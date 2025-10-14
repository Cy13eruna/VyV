# 📋 TECHNOLOGY DETAILS SYSTEM

## Overview
The technology system now includes detailed information dialogs that appear when clicking on technology buttons. These dialogs provide comprehensive information about each technology, including descriptions, usage instructions, and confirmation options.

## Dialog Features

### Technology Details Dialog
- **Trigger**: Clicking on any technology button
- **Content**: Detailed description, usage instructions, and planned features
- **Actions**: UPGRADE button (for available techs) or CLOSE button (for obtained techs)
- **Styling**: Consistent with game's dialog system using GameDialogStrings

### Dialog Components

#### Header Section
- **Technology Emoji**: Large 32px emoji representing the technology
- **Technology Name**: 24px white text showing the technology name
- **Layout**: Horizontal arrangement for visual appeal

#### Description Section
- **Rich Text**: BBCode-enabled RichTextLabel for formatted content
- **Size**: 400x150 pixels for adequate content display
- **Formatting**: Color-coded sections with proper typography

#### Button Section
- **UPGRADE Button**: Available for technologies that can be researched
- **CANCEL/CLOSE Button**: Always available for dialog dismissal
- **Styling**: Consistent button styling with 16px font size

## Content Structure

### Tier Information
Each technology description includes:
- **Tier Classification**: Tier 1 (Base) or Tier 2 (Advanced)
- **Prerequisites**: Required technologies for Tier 2 techs
- **Color Coding**: Yellow for Tier 1, Orange for Tier 2

### Technology Descriptions

#### Tier 1 Technologies (Fully Implemented)

##### 🚩 Settler
- **Purpose**: Domain establishment and territorial expansion
- **Usage**: Step-by-step instructions for using Settler ability
- **Requirements**: 1+ power in natal domain

##### 🧺 Harvest
- **Purpose**: Resource gathering and domain upgrades
- **Usage**: Domain upgrade process explanation
- **Effect**: Increases domain resource generation

##### ♥ Healer
- **Purpose**: Unit healing and support abilities
- **Usage**: Healing action instructions
- **Effect**: Restores health to damaged units

##### 🗡 Fighter
- **Purpose**: Combat enhancement and battle effectiveness
- **Usage**: Combat system explanation
- **Effect**: Enhanced damage and combat options

##### 🎣 Fish
- **Purpose**: Marine resources and coastal domain upgrades
- **Usage**: Fish upgrade process for coastal domains
- **Effect**: Enhanced marine resource production

#### Tier 2 Technologies (Placeholders)

##### Settler Branch
- **🐎 Rider**: Mounted movement and enhanced mobility
- **🤝🏻 Market**: Trade systems and economic bonuses

##### Harvest Branch
- **⛰ Climber**: Mountain traversal and terrain advantages
- **🏘 Hamlet**: Settlement expansion and population growth

##### Healer Branch
- **🪽 Shaman**: Spiritual powers and mystical abilities
- **🛡 Guardian**: Defensive mastery and protection systems

##### Fighter Branch
- **🪓 Warrior**: Melee combat specialization
- **🏹 Archer**: Ranged combat and siege capabilities

##### Fish Branch
- **〰 Sailor**: Naval mastery and water traversal
- **🐋 Whale**: Advanced marine resource gathering

## BBCode Formatting

### Color Scheme
- **Yellow**: Tier 1 technology headers
- **Orange**: Tier 2 technology headers
- **Gray**: Prerequisite and meta information
- **Cyan**: "How to use" section headers
- **White**: Default text color

### Text Formatting
- **[b]Bold[/b]**: Section headers and important terms
- **[i]Italic[/i]**: "Coming Soon" indicators for placeholders
- **[color=X]**: Color coding for different information types
- **Bullet Points**: • character for list items

## User Interaction Flow

### For Available Technologies
1. **Click Technology Button** → Details dialog opens
2. **Read Description** → Understand technology benefits
3. **Click UPGRADE** → Confirm technology research
4. **Technology Acquired** → Dialog closes, main tree updates

### For Obtained Technologies
1. **Click Technology Button** → Details dialog opens (view-only)
2. **Read Description** → Review technology information
3. **Click CLOSE** → Dialog closes

### For Unavailable Technologies
- **Button Disabled**: Cannot click unavailable technologies
- **Visual Indicator**: Red tint shows technology is locked
- **Prerequisite Clear**: Connection lines show what's needed

## Technical Implementation

### Key Functions
- `_on_technology_clicked()` - Handles initial button clicks
- `_show_technology_details()` - Creates and displays detail dialog
- `_get_technology_description()` - Generates formatted descriptions
- `_on_upgrade_confirmed()` - Handles upgrade confirmation
- `_on_details_closed()` - Handles dialog dismissal

### Dialog Management
- **Parent Dialog Tracking**: Maintains reference to main technology tree
- **Proper Cleanup**: Ensures dialogs are properly freed
- **Event Handling**: Connects button signals correctly
- **Styling Consistency**: Uses GameDialogStrings for uniform appearance

## Content Guidelines

### Description Writing
- **Clear Purpose**: Each technology has a clear, concise purpose statement
- **Practical Instructions**: Step-by-step usage instructions for implemented features
- **Future Vision**: Planned features for placeholder technologies
- **Consistent Format**: All descriptions follow the same structure

### Placeholder Content
- **"Coming Soon" Indicator**: Clear marking for unimplemented features
- **Planned Features**: Detailed list of intended functionality
- **Consistent Expectations**: Sets appropriate player expectations
- **Future-Proof**: Descriptions can be easily updated when features are implemented

## Benefits

### User Experience
- **Informed Decisions**: Players understand what they're researching
- **Clear Instructions**: No guesswork about how to use technologies
- **Progress Transparency**: Clear indication of what's implemented vs. planned
- **Consistent Interface**: Familiar dialog patterns throughout the game

### Development Benefits
- **Documentation Integration**: Descriptions serve as feature documentation
- **Placeholder Management**: Clear tracking of unimplemented features
- **User Feedback**: Players can understand and anticipate future features
- **Iterative Development**: Easy to update descriptions as features are added

## Future Enhancements

### Potential Improvements
- **Technology Icons**: Custom icons instead of emojis
- **Animated Previews**: Visual demonstrations of technology effects
- **Research Progress**: Progress bars for technologies being researched
- **Technology Trees**: Visual representation of complex dependency chains
- **Tooltips**: Quick hover information without opening full dialog

### Content Expansion
- **Historical Context**: Lore and background for each technology
- **Strategic Tips**: Advanced usage strategies and combinations
- **Video Tutorials**: Embedded demonstrations of technology usage
- **Community Content**: Player-contributed strategies and tips

The technology details system significantly improves the user experience by providing comprehensive information and clear guidance for technology research and usage.