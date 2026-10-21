<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['title', 'photo_path', 'published_at'])]
class WorkoutSession extends Model
{
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function entries(): HasMany
    {
        return $this->hasMany(WorkoutEntry::class)->orderBy('id');
    }

    protected function casts(): array
    {
        return [
            'published_at' => 'datetime',
        ];
    }
}
