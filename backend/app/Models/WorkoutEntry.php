<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['exercise_name', 'sets', 'reps', 'weight_kg'])]
class WorkoutEntry extends Model
{
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    protected function casts(): array
    {
        return [
            'sets' => 'integer',
            'reps' => 'integer',
            'weight_kg' => 'decimal:2',
        ];
    }
}
