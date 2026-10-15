<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WorkoutEntryController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'exercise_name' => ['required', 'string', 'max:120'],
            'sets' => ['required', 'integer', 'min:1', 'max:1000'],
            'reps' => ['required', 'integer', 'min:1', 'max:1000'],
            'weight_kg' => ['nullable', 'numeric', 'min:0', 'max:999999.99'],
        ]);

        $entry = $request->user()->workoutEntries()->create($validated);

        return response()->json([
            'message' => 'Workout logged successfully',
            'data' => $entry,
        ], 201);
    }
}
