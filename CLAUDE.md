# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Terrain** is a TCM (Traditional Chinese Medicine) daily rituals iOS app. This repository is currently in the **pre-development planning phase** containing specification documents only.

**Positioning**: "Co-Star clarity + Muji calm" for TCM lifestyle routines
**Target User**: Female-skewing, 19-35, astrology-influenced identity seeker, health-conscious
**MVP Platform**: iOS (iPhone)

## Repository Structure

This is a planning/specification repository with no source code yet. Documents are in RTF format:

- `PRD - TCM App.rtf` - Full product requirements document defining vision, personas, UX, and feature specifications
- `Content Schema JSON.rtf` - JSON Schema defining the content pack structure (ingredients, routines, movements, lessons, programs, terrain profiles)
- `Terrain Scoring Table.rtf` - Scoring algorithm for the 12-question onboarding quiz that determines user's Terrain type
- `Copy for Terrain Types.rtf` - Localized copy templates for all 8 primary terrain types and 5 modifiers

## Core Concepts

### Terrain System
Users are assigned a **Terrain** (body constitution type) based on quiz responses. Displayed as:
- **Primary Type** (8 types): Cold+Deficient, Cold+Balanced, Neutral+Deficient, Neutral+Balanced, Neutral+Excess, Warm+Balanced, Warm+Excess, Warm+Deficient
- **Nickname**: Human-friendly name (e.g., "Low Flame", "Steady Core", "Overclocked")
- **Modifier** (optional): Damp, Dry, Stagnation, Shen, or None

### Scoring Axes
The quiz scoring uses 5 axes:
- `cold_heat` (-10 to +10): Negative = cold, Positive = heat
- `def_excess` (-10 to +10): Negative = deficient, Positive = excess
- `damp_dry` (-10 to +10): Negative = damp, Positive = dry
- `qi_stagnation` (0 to 10): Higher = more stuck
- `shen_unsettled` (0 to 10): Higher = more sleep/mind unsettled

### Content Model
Content pack schema includes:
- **Ingredients**: TCM-aligned foods/herbs with axis tags, goals, seasons, regions
- **Routines**: Eat/drink rituals with steps, swaps, ingredient refs
- **Movements**: Illustrated exercise flows (3-7 min)
- **Lessons**: Field Guide educational content
- **Programs**: Multi-day structured programs (3-30 days)
- **TerrainProfiles**: Full profile definitions with superpowers, traps, truths

## Design Principles

When implementing features, follow these principles from the PRD:

1. **Co-Star simplicity**: 1 question per screen; "reveal moment" that feels specific
2. **Muji calm**: Whitespace, subtle motion, low-saturation palette, quiet copy
3. **Explainable recommendations**: 1-line "why" with expandable tooltips (hybrid terms)
4. **Culturally grounded**: Provenance blurbs and "common home practice" framing
5. **Low friction**: Default plan works even if user skips daily logging
6. **Accessibility**: Pantry-based suggestions; no exotic ingredient dependency
7. **Safety**: Conservative defaults + safety gate + soft warnings

## Content Tone

- Muji-calm, chic, informational
- Avoid snark
- Short sentences
- Gentle confidence
- Never say "diagnosis" - use "profile," "terrain," "pattern"
- Surface human terms + light TCM; expand with proper TCM framework via tooltips

## MCP Servers Available

- `puppeteer` - Browser automation (prefer Playwright when possible)
- `browser-tools-mcp` - Browser debugging
- `supabase` - Database operations
- `shadcn-ui` - UI component library
- `filesystem` - File operations
- `@21st-dev/magic` - UI component generation

## Testing Preferences

- **Browser automation**: Prefer Playwright over Puppeteer for testing and browser automation tasks

## Next Steps for Development

When development begins, the app will need:
1. iOS app (Swift/SwiftUI) following the PRD specifications
2. Backend API for content delivery and user profiles
3. Content pipeline to validate/transform the JSON content packs
4. Onboarding quiz implementing the scoring algorithm from `Terrain Scoring Table.rtf`
5. Content authoring following the schema in `Content Schema JSON.rtf`
