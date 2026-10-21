<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\WorkoutEntryController;
use App\Http\Controllers\WorkoutSessionController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register'])
    ->middleware('throttle:5,1');

Route::post('/login', [AuthController::class, 'login'])
    ->middleware('throttle:5,1');

Route::middleware('auth:sanctum')->group(function (): void {
    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/users', [AuthController::class, 'users']);
    Route::post('/workouts', [WorkoutEntryController::class, 'store']);
    Route::get('/workout-sessions', [WorkoutSessionController::class, 'index']);
    Route::post('/workout-sessions', [WorkoutSessionController::class, 'store']);
});
