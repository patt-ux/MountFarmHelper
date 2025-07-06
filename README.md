# Mount Farm Helper

A World of Warcraft add-on to help track mount farming attempts and lockouts.

## Features

- **Uncollected Mount List**: Shows all mounts you haven't collected yet
- **Lockout Tracking**: Displays when instance lockouts expire for raid/dungeon mounts
- **Want to Farm Toggle**: Mark mounts you want to farm (persists across sessions)
- **Advanced Filtering**: Filter by:
  - Instance Type (Dungeon, Raid, World Boss, etc.)
  - Zone (specific raid/dungeon names)
  - Expansion (Classic through Dragonflight)
  - Lockout Status (Available, Locked)

## Installation

1. Download the `MountFarmHelper` folder
2. Place it in your `World of Warcraft/_retail_/Interface/AddOns/` directory
3. Restart World of Warcraft or reload your UI (`/reload`)
4. The add-on should appear in your add-ons list

## Usage

- **Open the add-on**: Type `/mfh` in chat
- **Refresh data**: Click the "Refresh" button to update mount and lockout information
- **Filter mounts**: Use the dropdown menus to filter the mount list
- **Mark for farming**: Check the checkbox next to mounts you want to farm
- **View lockouts**: The lockout column shows remaining time or "Available" status

## How It Works

The add-on scans your Mount Journal for uncollected mounts and categorizes them based on their source. For raid and dungeon mounts, it checks your saved instances to determine lockout status.

## Data Persistence

Your "want to farm" selections are saved and will persist across game sessions and character logins.

## Troubleshooting

- If the add-on doesn't load, make sure it's in the correct directory
- If mount data seems incorrect, try clicking the "Refresh" button
- For lockout information to be accurate, you need to have attempted the instance at least once

## Future Enhancements

- More accurate expansion detection
- Better zone name extraction
- Attempt tracking and statistics
- Integration with other farming add-ons
- Export/import functionality

## Requirements

- World of Warcraft Retail (not Classic)
- Interface version 100207 or higher 