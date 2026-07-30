<?php

declare(strict_types=1);

it('renders the welcome page', function (): void {
    visit('/')->assertSee('Log in');
});
