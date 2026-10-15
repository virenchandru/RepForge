<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class WorkoutEntryTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_authenticated_user_can_log_a_workout_entry(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test-token')->plainTextToken;

        $this->withToken($token)
            ->postJson('/api/workouts', [
                'exercise_name' => 'Squat',
                'sets' => 3,
                'reps' => 10,
                'weight_kg' => 42.5,
            ])
            ->assertCreated()
            ->assertJsonPath('message', 'Workout logged successfully')
            ->assertJsonPath('data.user_id', $user->id)
            ->assertJsonPath('data.exercise_name', 'Squat')
            ->assertJsonPath('data.sets', 3)
            ->assertJsonPath('data.reps', 10)
            ->assertJsonPath('data.weight_kg', '42.50')
            ->assertJsonStructure([
                'data' => ['id', 'created_at'],
            ]);

        $this->assertDatabaseHas('workout_entries', [
            'user_id' => $user->id,
            'exercise_name' => 'Squat',
            'sets' => 3,
            'reps' => 10,
            'weight_kg' => 42.5,
        ]);
    }

    public function test_workout_entry_requires_valid_exercise_details(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test-token')->plainTextToken;

        $this->withToken($token)
            ->postJson('/api/workouts', [
                'exercise_name' => '',
                'sets' => 0,
                'reps' => -1,
                'weight_kg' => -2,
            ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'exercise_name',
                'sets',
                'reps',
                'weight_kg',
            ]);

        $this->assertDatabaseCount('workout_entries', 0);
    }

    public function test_guest_cannot_log_a_workout_entry(): void
    {
        $this->postJson('/api/workouts', [
            'exercise_name' => 'Squat',
            'sets' => 3,
            'reps' => 10,
        ])->assertUnauthorized();

        $this->assertDatabaseCount('workout_entries', 0);
    }
}
