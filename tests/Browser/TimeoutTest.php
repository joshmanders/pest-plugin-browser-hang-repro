<?php

declare(strict_types=1);

it('fails within the configured timeout when the text never appears', function (): void {
    visit('/')->assertSee('THIS TEXT NEVER APPEARS ON THE PAGE');
});
