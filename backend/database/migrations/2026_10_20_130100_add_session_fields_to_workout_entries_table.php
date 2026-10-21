<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('workout_entries', function (Blueprint $table) {
            $table->foreignId('workout_session_id')
                ->nullable()
                ->after('user_id')
                ->constrained('workout_sessions')
                ->cascadeOnDelete();
            $table->unsignedSmallInteger('set_number')->nullable()->after('sets');
        });
    }

    public function down(): void
    {
        Schema::table('workout_entries', function (Blueprint $table) {
            $table->dropConstrainedForeignId('workout_session_id');
            $table->dropColumn('set_number');
        });
    }
};
