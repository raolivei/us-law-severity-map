# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2025-10-29

### Added

- Interactive click-to-zoom functionality for all 50 states
- Professional statistics panel with comprehensive data overlay
- Crime statistics: murder rates, gun deaths, traffic fatalities (per 100k)
- Population and incarceration rate data for each state
- Plotly-based interactive visualization with smooth animations
- US average comparisons for crime statistics
- Close button and double-click reset functionality
- Standalone HTML export with offline functionality

### Changed

- Migrated from matplotlib to Plotly for advanced interactivity
- Hover now shows only state names; detailed stats appear on click
- Converted all text from Portuguese to English
- Improved zoom centering with state-specific coordinates
- Enhanced color gradient and visual design

### Fixed

- JSON parsing errors in JavaScript
- Event handling for click interactions
- Map centering when zooming to states

## [1.0.0] - 2025-10-28

### Added

- Initial release with static choropleth map
- Law severity scoring system (0-100 scale)
- Death penalty status for all 50 states
- Automatic US Census Bureau shapefile download
- Basic matplotlib visualization
- Documentation and README

---

**Current Version**: 2.0.0  
**Repository**: https://github.com/raolivei/us-law-severity-map
