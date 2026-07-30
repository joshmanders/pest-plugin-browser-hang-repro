<?php

declare(strict_types=1);

it('fails instead of hanging when clicking a zero-match locator', function (): void {
    visit('/')->click('button[data-nonexistent-hook="definitely-not-here"]');
});
