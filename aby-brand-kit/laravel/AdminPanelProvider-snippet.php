<?php
// app/Providers/Filament/AdminPanelProvider.php — merge into your panel() method.
// First copy:  aby-brand-kit/logos/svg/*.svg  -> public/brand/
//              aby-brand-kit/icons/favicon.ico -> public/favicon.ico (and public/brand/)
// Written against the Filament v3/v4 panel API; check names against the version you install.

use Filament\Panel;
use Filament\Support\Colors\Color;

public function panel(Panel $panel): Panel
{
    return $panel
        // ...your existing config...
        ->brandName('Aby')
        ->brandLogo(asset('brand/aby-lockup.svg'))
        ->darkModeBrandLogo(asset('brand/aby-lockup-dark.svg'))
        ->brandLogoHeight('2rem')
        ->favicon(asset('brand/favicon.ico'))
        ->font('Figtree')
        ->colors([
            'primary' => Color::hex('#101322'), // midnight: main actions
            'info'    => Color::hex('#3446e0'), // signal blue: links, selection
            'success' => Color::hex('#3f5a00'), // lime ink: synced, sale complete
            'warning' => Color::hex('#8a5300'), // offline, low stock
            'danger'  => Color::hex('#c2361b'), // voids, errors, overdue credit
            'gray'    => Color::Zinc,
        ]);
}
