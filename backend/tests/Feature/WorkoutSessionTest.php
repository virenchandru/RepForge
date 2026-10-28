<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\WorkoutSession;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class WorkoutSessionTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_previous_performance_returns_only_latest_published_matching_exercise_sets(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();

        $this->createSession($user, 'Old leg day', now()->subDays(3), [
            ['exercise_name' => 'Squat', 'set_number' => 1, 'reps' => 12, 'weight_kg' => 30],
        ]);
        $latest = $this->createSession($user, 'Latest mixed day', now()->subDay(), [
            ['exercise_name' => 'Squat', 'set_number' => 2, 'reps' => 6, 'weight_kg' => null],
            ['exercise_name' => 'Squat', 'set_number' => 1, 'reps' => 8, 'weight_kg' => 40],
            ['exercise_name' => 'Bench Press', 'set_number' => 1, 'reps' => 10, 'weight_kg' => 22.5],
        ]);
        $this->createSession($user, 'Unpublished draft', null, [
            ['exercise_name' => 'Squat', 'set_number' => 1, 'reps' => 20, 'weight_kg' => 100],
        ]);
        $this->createSession($otherUser, 'Other athlete latest', now(), [
            ['exercise_name' => 'Squat', 'set_number' => 1, 'reps' => 1, 'weight_kg' => 999],
        ]);

        $token = $user->createToken('test-token')->plainTextToken;
        $this->withToken($token)
            ->getJson('/api/workout-sessions/previous-performance?exercise_name=Squat')
            ->assertOk()
            ->assertJsonPath('data.title', 'Latest mixed day')
            ->assertJsonPath('data.published_at', $latest->published_at->toISOString())
            ->assertJsonCount(2, 'data.entries')
            ->assertJsonPath('data.entries.0.exercise_name', 'Squat')
            ->assertJsonPath('data.entries.0.set_number', 1)
            ->assertJsonPath('data.entries.0.reps', 8)
            ->assertJsonPath('data.entries.0.weight_kg', '40.00')
            ->assertJsonPath('data.entries.1.set_number', 2)
            ->assertJsonPath('data.entries.1.weight_kg', null);

        $this->withToken($token)
            ->getJson('/api/workout-sessions/previous-performance?exercise_name=Bench%20Press')
            ->assertOk()
            ->assertJsonPath('data.title', 'Latest mixed day')
            ->assertJsonCount(1, 'data.entries')
            ->assertJsonPath('data.entries.0.exercise_name', 'Bench Press');
    }

    public function test_previous_performance_returns_empty_and_requires_authentication(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test-token')->plainTextToken;

        $this->getJson('/api/workout-sessions/previous-performance?exercise_name=Plank')
            ->assertUnauthorized();

        $this->withToken($token)
            ->getJson('/api/workout-sessions/previous-performance?exercise_name=Plank')
            ->assertOk()
            ->assertExactJson(['data' => null]);
    }

    /**
     * @param  list<array{exercise_name: string, set_number: int, reps: int, weight_kg: float|null}>  $entries
     */
    private function createSession(User $user, string $title, mixed $publishedAt, array $entries): WorkoutSession
    {
        $session = $user->workoutSessions()->create([
            'title' => $title,
            'published_at' => $publishedAt,
        ]);

        foreach ($entries as $entry) {
            $session->entries()->create([
                'user_id' => $user->id,
                ...$entry,
                'sets' => 1,
            ]);
        }

        return $session;
    }

    public function test_user_can_publish_a_workout_with_photo_and_list_it_in_history(): void
    {
        Storage::fake('public');
        $user = User::factory()->create();
        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withToken($token)->post('/api/workout-sessions', [
            'title' => 'Leg day',
            'photo' => UploadedFile::fake()->create('session.jpg', 10, 'image/jpeg'),
            'entries' => json_encode([
                [
                    'exercise_name' => 'Squat',
                    'set_number' => 1,
                    'reps' => 8,
                    'weight_kg' => 40,
                ],
                [
                    'exercise_name' => 'Squat',
                    'set_number' => 2,
                    'reps' => 6,
                    'weight_kg' => 45,
                ],
            ]),
        ], ['Accept' => 'application/json']);

        $response
            ->assertCreated()
            ->assertJsonPath('message', 'Workout published successfully')
            ->assertJsonPath('data.title', 'Leg day')
            ->assertJsonPath('data.entries.0.exercise_name', 'Squat')
            ->assertJsonPath('data.entries.0.set_number', 1)
            ->assertJsonPath('data.entries.1.reps', 6);

        Storage::disk('public')->assertExists($response->json('data.photo_path'));
        $this->assertDatabaseCount('workout_sessions', 1);
        $this->assertDatabaseCount('workout_entries', 2);

        $this->withToken($token)
            ->getJson('/api/workout-sessions')
            ->assertOk()
            ->assertJsonPath('data.0.title', 'Leg day')
            ->assertJsonCount(2, 'data.0.entries');
    }

    public function test_workout_history_is_limited_to_the_authenticated_user(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $user->workoutSessions()->create([
            'title' => 'My workout',
            'published_at' => now(),
        ]);
        $otherUser->workoutSessions()->create([
            'title' => 'Another workout',
            'published_at' => now(),
        ]);

        $token = $user->createToken('test-token')->plainTextToken;
        $this->withToken($token)
            ->getJson('/api/workout-sessions')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.title', 'My workout');
    }
}
