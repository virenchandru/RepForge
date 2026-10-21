<?php

namespace App\Http\Controllers;

use App\Models\WorkoutSession;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Throwable;

class WorkoutSessionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $sessions = $request->user()
            ->workoutSessions()
            ->with('entries')
            ->latest('published_at')
            ->get();

        return response()->json([
            'data' => $sessions->map(fn (WorkoutSession $session) => $this->serialize($session)),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $entries = $request->input('entries');
        if (is_string($entries)) {
            $request->merge(['entries' => json_decode($entries, true)]);
        }

        $validated = $request->validate([
            'title' => ['required', 'string', 'max:120'],
            'photo' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:10240'],
            'entries' => ['required', 'array', 'min:1', 'max:1000'],
            'entries.*.exercise_name' => ['required', 'string', 'max:120'],
            'entries.*.set_number' => ['required', 'integer', 'min:1', 'max:1000'],
            'entries.*.reps' => ['required', 'integer', 'min:1', 'max:1000'],
            'entries.*.weight_kg' => ['nullable', 'numeric', 'min:0', 'max:999999.99'],
        ]);

        $photoPath = null;
        if ($request->hasFile('photo')) {
            $storedPath = $request->file('photo')->store('workout-sessions', 'public');
            if (! is_string($storedPath)) {
                throw new \RuntimeException('Unable to store workout photo.');
            }
            $photoPath = $storedPath;
        }

        try {
            $session = DB::transaction(function () use ($request, $validated, $photoPath) {
                $session = $request->user()->workoutSessions()->create([
                    'title' => $validated['title'],
                    'photo_path' => $photoPath,
                    'published_at' => now(),
                ]);

                foreach ($validated['entries'] as $entry) {
                    $session->entries()->create([
                        'user_id' => $request->user()->id,
                        'exercise_name' => $entry['exercise_name'],
                        'sets' => 1,
                        'set_number' => $entry['set_number'],
                        'reps' => $entry['reps'],
                        'weight_kg' => $entry['weight_kg'] ?? null,
                    ]);
                }

                return $session->load('entries');
            });
        } catch (Throwable $error) {
            if ($photoPath !== null) {
                Storage::disk('public')->delete($photoPath);
            }
            throw $error;
        }

        return response()->json([
            'message' => 'Workout published successfully',
            'data' => $this->serialize($session),
        ], 201);
    }

    /**
     * @return array<string, mixed>
     */
    private function serialize(WorkoutSession $session): array
    {
        return [
            'id' => $session->id,
            'title' => $session->title,
            'photo_path' => $session->photo_path,
            'published_at' => $session->published_at?->toISOString(),
            'entries' => $session->entries->map(fn ($entry) => [
                'id' => $entry->id,
                'exercise_name' => $entry->exercise_name,
                'set_number' => $entry->set_number,
                'reps' => $entry->reps,
                'weight_kg' => $entry->weight_kg,
            ])->values(),
        ];
    }
}
