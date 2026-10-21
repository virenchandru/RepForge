<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class WorkoutSessionTest extends TestCase
{
    use LazilyRefreshDatabase;

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
