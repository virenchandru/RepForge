<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['user_id', 'workout_session_id', 'exercise_name', 'sets', 'set_number', 'reps', 'weight_kg'])]
class WorkoutEntry extends Model
{
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function workoutSession(): BelongsTo
    {
        return $this->belongsTo(WorkoutSession::class);
    }

    protected function casts(): array
    {
        return [
            'sets' => 'integer',
            'set_number' => 'integer',
            'reps' => 'integer',
            'weight_kg' => 'decimal:2',
        ];
    }
}
