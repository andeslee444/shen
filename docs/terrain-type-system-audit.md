# Terrain Type System: TCM Audit & Designer Reference

**Audience:** UI/UX onboarding tutorial designer
**Purpose:** Understand the theoretical foundation behind terrain types, how the quiz assigns them, and how to communicate them to users during onboarding

---

## Part 1: TCM Audit — Does This Model Hold Up?

### The short answer

Yes — with nuance. Terrain's 2-axis + modifier system is a thoughtful simplification of a real TCM framework called **body constitution theory** (体质学, tǐ zhì xué). It's not a dumbed-down version of TCM. It's a deliberate translation of the most clinically relevant dimensions into language and structure a modern user can grasp in under 2 minutes.

Here's the detailed assessment.

### What Terrain is based on: the Wang Qi 9-Constitution Model

The closest formal TCM framework is Professor Wang Qi's (王琦) **Nine Body Constitution Types**, published in 2005 and adopted by the China Association of Chinese Medicine as a national standard in 2009. It's the most widely used constitution classification in modern TCM clinical practice.

Wang Qi's 9 types:

| # | Chinese | English | Core pattern |
|---|---------|---------|------------|
| 1 | 平和质 | Balanced | Healthy baseline |
| 2 | 气虚质 | Qi Deficient | Low energy, weak digestion, catches colds easily |
| 3 | 阳虚质 | Yang Deficient | Feels cold, low metabolism, pale |
| 4 | 阴虚质 | Yin Deficient | Feels warm, dry, restless sleep, thin |
| 5 | 痰湿质 | Phlegm-Damp | Heavy, bloated, sluggish, mucusy |
| 6 | 湿热质 | Damp-Heat | Oily skin, irritable, yellow-tinted complexion |
| 7 | 血瘀质 | Blood Stasis | Dark complexion, pain, poor circulation |
| 8 | 气郁质 | Qi Stagnation | Emotional tension, sighing, mood swings |
| 9 | 特禀质 | Special/Allergic | Hypersensitive, allergies |

### How Terrain maps to Wang Qi

Terrain doesn't use these 9 types directly — it **decomposes them into underlying axes**, which is actually a more flexible and accurate approach. Here's the mapping:

| Wang Qi Type | Terrain Equivalent | How Terrain captures it |
|-------------|-------------------|----------------------|
| Balanced (平和质) | Neutral + Balanced (Steady Core) | coldHeat ≈ 0, defExcess ≈ 0 |
| Qi Deficient (气虚质) | Neutral + Deficient (Low Battery) | defExcess ≤ -3, coldHeat neutral |
| Yang Deficient (阳虚质) | Cold + Deficient (Low Flame) | coldHeat ≤ -3, defExcess ≤ -3 |
| Yin Deficient (阴虚质) | Warm + Deficient (Bright but Thin) | coldHeat ≥ 3, defExcess ≤ -3 |
| Phlegm-Damp (痰湿质) | Any primary + **Damp modifier** | dampDry ≤ -3 |
| Damp-Heat (湿热质) | Warm + Excess + **Damp modifier** | coldHeat ≥ 3, defExcess ≥ 3, dampDry ≤ -3 |
| Blood Stasis (血瘀质) | Partially captured by **Stagnation modifier** | qiStagnation ≥ 4 (Qi stagnation often precedes Blood stasis in TCM) |
| Qi Stagnation (气郁质) | **Stagnation modifier** | qiStagnation ≥ 4 |
| Special/Allergic (特禀质) | **Not captured** | Correct omission — see below |

### What Terrain gets right

**1. The two primary axes are the most fundamental in TCM diagnosis.**

Cold/Heat (寒热) and Deficiency/Excess (虚实) are two of the **Eight Principles** (八纲辨证), the foundational diagnostic framework that every TCM practitioner uses before any other system. They're not arbitrary choices — they're the first two questions any TCM doctor asks: "Is this person running hot or cold?" and "Is their body depleted or overloaded?"

The other two Eight Principles (Interior/Exterior and Yin/Yang) are either redundant at this level (Yin/Yang is the umbrella of Cold/Heat + Def/Excess) or not relevant to a lifestyle app (Interior/Exterior distinguishes acute illness from chronic constitution).

**Verdict: Excellent axis choice. This is textbook-correct prioritization.**

**2. The modifier layer correctly separates secondary patterns from primary constitution.**

In clinical TCM, a patient has a *primary constitution* (e.g., Yang Deficient) and often a *secondary complication* (e.g., with Dampness). Terrain's architecture mirrors this: the 2-axis grid determines who you fundamentally are, and the modifier adds what's currently going on on top of that.

The priority order (Shen > Stagnation > Damp/Dry) is also clinically sound:
- **Shen disturbance** (神不安) affects sleep and cognition — if someone isn't sleeping, nothing else matters. Addressing this first is correct triage.
- **Qi Stagnation** (气滞) is the precursor to many other problems. Unresolved stagnation generates heat, dampness, and eventually blood stasis. Catching it early is good practice.
- **Damp/Dry** are fluid metabolism patterns that develop more slowly and are less urgent than mind/sleep disruption.

**Verdict: The modifier architecture is clinically sound and the priority order reflects real TCM triage logic.**

**3. Omitting the "Special/Allergic" (特禀质) type is correct.**

Wang Qi's 9th type describes genetic hypersensitivity and allergic constitution. It's fundamentally different from the other 8 — it's not a pattern you can address through food and lifestyle in the same way. Including it in a lifestyle app would create false promises. Terrain is right to leave it out.

**Verdict: Smart omission.**

### What Terrain could do better (minor)

**1. The "Cold + Excess" gap.**

The 3×3 grid theoretically has 9 cells, but Terrain only defines 8 types. Cold + Excess is mapped to Cold + Balanced (line 177 in the scoring engine: `case (.cold, .excess): return .coldBalanced`).

From a TCM perspective, Cold + Excess does exist — it's called "Excess Cold" or "Cold Accumulation" (寒实证). Think of someone with a strong constitution who ate too much raw/cold food and now has severe cramping, constipation, and a forceful-but-slow pulse. It's uncommon as a *chronic constitution* (which is what Terrain measures), so collapsing it into Cold + Balanced is defensible. But it's worth knowing the gap exists.

**Assessment: Acceptable simplification. Cold + Excess is rare as a baseline constitution.**

**2. Blood Stasis (血瘀质) is only partially captured.**

Terrain's Stagnation modifier captures **Qi Stagnation** (气滞), which is the precursor to Blood Stasis (血瘀). But Blood Stasis itself — characterized by fixed sharp pain, dark complexion, purple lips, and spider veins — isn't directly measured. The quiz doesn't ask about bruising, fixed pain, or complexion color.

This is a reasonable scope decision for a lifestyle app (Blood Stasis often requires clinical intervention, not just dietary changes), but it means some users with Blood Stasis patterns will be classified as Stagnation, which is close but not identical.

**Assessment: Acceptable scope limitation. The quiz could add 1 question about bruising/pain quality in a future version.**

**3. The nicknames are strong but could be more evocative.**

"Low Flame," "Cool Core," "Overclocked" — these are genuinely good. They communicate something physical and intuitive. A few observations:

- **"Low Battery"** (Neutral + Deficient) is the weakest nickname. Batteries are replaceable objects — the metaphor implies the person is a device that needs charging. Something like "Quiet Reserves" or "Gentle Engine" might feel less clinical.
- **"Busy Mind"** (Neutral + Excess) is accurate but focuses only on the mental dimension. This type also manifests as physical tension and digestive issues. "Wound Up" or "High Idle" might capture both.
- **"Bright but Thin"** (Warm + Deficient) is the most poetic and the best of the set. It perfectly captures Yin Deficiency in three words.

**Assessment: Minor — the nicknames work well overall. These are suggestions, not corrections.**

---

## Part 2: How the System Works (For the Designer)

### The mental model: a weather station for your body

Imagine your body has an internal weather station with 5 sensors:

```
 SENSOR 1: THERMOSTAT          ← Am I running cold or hot?
            ◄──────────────────────────────►
          -10 (freezing)    0 (neutral)    +10 (overheating)

 SENSOR 2: FUEL GAUGE          ← Am I depleted or overloaded?
            ◄──────────────────────────────►
          -10 (empty)       0 (balanced)   +10 (overfull)

 SENSOR 3: MOISTURE METER      ← Am I waterlogged or dried out?
            ◄──────────────────────────────►
          -10 (swamp)       0 (balanced)   +10 (desert)

 SENSOR 4: FLOW METER          ← Is my energy stuck or moving?
            ────────────────────────────────►
           0 (flowing)                     +10 (gridlocked)

 SENSOR 5: CALM METER          ← Is my mind settled or restless?
            ────────────────────────────────►
           0 (peaceful)                    +10 (racing)
```

The quiz is a 13-16 question conversation that reads these sensors. Each answer nudges one or more sensors in a direction. At the end, we read the dashboard.

### From sensors to identity: the two-step process

**Step 1: Read the thermostat and fuel gauge → Your primary type (who you are)**

These two sensors create a 3×3 grid. The user lands in one of 8 cells (Cold + Excess is collapsed):

```
                    DEPLETED          BALANCED          OVERLOADED
                   (≤ -3)           (-2 to +2)           (≥ +3)
              ┌─────────────────┬─────────────────┬─────────────────┐
    COLD      │   🕯️ Low Flame  │  🧊 Cool Core    │   (→ Cool Core) │
   (≤ -3)    │   Yang Deficient│  Cold pattern    │   rare; mapped  │
              ├─────────────────┼─────────────────┼─────────────────┤
   NEUTRAL    │  🪫 Low Battery │  ⚖️ Steady Core  │  🧠 Busy Mind   │
  (-2 to +2) │  Qi Deficient   │  Balanced        │  Excess pattern │
              ├─────────────────┼─────────────────┼─────────────────┤
    WARM      │ 🏜️ Bright/Thin │  🔥 High Flame   │  ⚡ Overclocked │
   (≥ +3)    │  Yin Deficient  │  Warm pattern    │  Yang Excess    │
              └─────────────────┴─────────────────┴─────────────────┘
```

This is the user's **core identity** — their terrain type. It doesn't change day to day. Think of it like knowing whether you're naturally fair-skinned or olive-skinned. It informs everything else.

**Step 2: Read the other three sensors → Your modifier (what's happening right now)**

The moisture meter, flow meter, and calm meter can flag a secondary pattern layered on top. Only the strongest signal wins (priority: Shen > Stagnation > Damp/Dry):

| Modifier | Sensor | Threshold | What it means in plain language |
|----------|--------|-----------|-------------------------------|
| **Shen** (Restless) | Calm meter ≥ 4 | Your mind is running ahead of your body. Sleep is disrupted. Thoughts loop. |
| **Stagnation** (Stuck) | Flow meter ≥ 4 | Your energy is jammed. You feel tense, irritable, sighy. Things aren't flowing. |
| **Damp** (Heavy) | Moisture meter ≤ -3 | Your body is holding onto too much fluid/heaviness. Bloated, foggy, sluggish. |
| **Dry** (Thirsty) | Moisture meter ≥ 3 | Your body is drying out. Dry skin, lips, throat. Thirsty. Constipated. |
| **None** | All below threshold | No strong secondary pattern. Your primary type tells the full story. |

So a complete terrain reading looks like:

> **"You're a Low Flame with a Damp modifier"**
> Translation: You run cold and depleted (Low Flame), and on top of that, your body is holding extra dampness (bloating, heaviness).

Or:

> **"You're an Overclocked with Shen"**
> Translation: You run hot and wired (Overclocked), and your mind won't settle down (Shen restlessness).

### What the terrain type unlocks in the app

Once the user has their type, every screen in the app becomes personalized:

| Feature | How terrain shapes it |
|---------|----------------------|
| **Home tab headline** | Daily editorial statement changes based on type + current symptoms |
| **Do/Don't lists** | "Do" items match recommended_tags; "Don't" items match avoid_tags |
| **Ingredient ranking** | Ingredients tagged with recommended_tags sort higher; avoid_tags sort lower |
| **Routine suggestions** | Routines with matching terrain_fit appear first |
| **"Why for you" text** | Every ingredient and routine gets a terrain-specific explanation |
| **Seasonal guidance** | Combined with the 5-season system to say "you + this season = do this" |

---

## Part 3: Communicating This in Onboarding

### The challenge

The user just answered 13 questions and is about to be told they're a "Cold + Deficient Low Flame with Damp modifier." That sounds like a medical diagnosis from a fantasy novel. The onboarding has to make this feel:

1. **Immediately recognizable** — "Oh, that IS me"
2. **Non-medical** — This is a profile, not a diagnosis
3. **Actionable** — "Now I know what to do differently"
4. **Empowering** — Every type has a superpower, not just a problem

### The reveal structure (current implementation)

The onboarding currently uses a multi-phase reveal:

**Phase 1: Identity moment** (TerrainRevealView)
- Terrain type name + nickname (e.g., "Cold + Deficient — Low Flame")
- 5-axis radar/pattern visualization showing the vector shape
- Superpower statement (what's great about this type)
- Trap statement (what to watch for)

**Phase 2: Tutorial preview** (TutorialPreviewView, 4 screens)
- Screen 1: "Your Daily Read" — shows the personalized headline and do/don'ts
- Screen 2: "How It Adapts" — interactive symptom chips that change content
- Screen 3: "Your Starter Kit" — signature ritual + recommended ingredients
- Screen 4: "Your Ingredients" — shows tag matching (why ginger is great for you, why green tea isn't)

### Design principles for terrain communication

**1. Lead with the nickname, not the clinical label.**

Users should think of themselves as a "Low Flame" — not as "Cold + Deficient." The clinical label is available for the curious, but the nickname is the primary identity token. It should appear on the reveal screen, in the You tab header, and anywhere the type is referenced.

Good: "You're a **Low Flame** 🕯️"
Less good: "Your terrain is Cold + Deficient (Low Flame)"

**2. The superpower should come before the trap.**

Every type is framed positively first. This isn't a list of problems. The superpower is what happens when this constitution is *supported*, and the trap is what happens when it's *neglected*. The user should feel seen, not pathologized.

Good flow: "Your superpower → Your trap → What Terrain does about it"
Bad flow: "Here's what's wrong → Here's your type → Good luck"

**3. The modifier should feel like weather, not identity.**

The primary type is who you are. The modifier is what's happening right now. This distinction matters for user psychology:

- Primary type: "You're a Low Flame" (permanent, identity-level)
- Modifier: "Right now, you're running damp" (temporary, addressable)

Design implication: the modifier should be visually subordinate to the primary type. A badge or subtitle, not a co-equal title.

**4. The 5 axes should be felt, not counted.**

Users don't need to know there are exactly 5 axes. They need to feel the shape of their pattern. A radar chart or wave visualization communicates "here's your unique shape" better than a list of numbers. The axes themselves (cold/heat, deficiency/excess, etc.) can be labeled with plain language:

| Axis | Technical | User-facing |
|------|-----------|------------|
| coldHeat | Cold-Heat spectrum | Thermal tendency |
| defExcess | Deficiency-Excess spectrum | Energy reserves |
| dampDry | Damp-Dry spectrum | Fluid balance |
| qiStagnation | Qi Stagnation | Flow / ease |
| shenUnsettled | Shen disturbance | Mind / calm |

**5. Show, don't tell — use the ingredient match screen.**

The most powerful onboarding moment is when the user sees *why* specific ingredients are recommended for them. This makes the abstract ("you're a Low Flame") concrete ("ginger warms your system, green tea would cool it further"). The tag-matching screen (Tutorial Screen 4) is where the type system proves its value.

---

## Part 4: Quick Reference for All 8 Types

### 🕯️ Low Flame (Cold + Deficient)

**TCM equivalent:** Yang Deficiency (阳虚质)
**In one sentence:** Your internal fire is low — you run cold, tire easily, and do best with warming, nourishing routines.
**The person:** Often has cold hands/feet, prefers hot drinks, gets sluggish after meals, catches colds easily, feels better in summer.
**Superpower:** Consistency makes you steady. Warmth and routine unlock your best energy.
**Trap:** Cold inputs and skipping meals drain you faster than you expect.
**Recommended tags:** warming, supports_deficiency, supports_digestion
**Avoid tags:** cooling
**Starter ingredients:** Ginger, Red Dates, Cinnamon, Oats, Rice, Sweet Potato

### 🧊 Cool Core (Cold + Balanced)

**TCM equivalent:** Cold pattern with adequate Qi (寒证, 气不虚)
**In one sentence:** You have good reserves but run cool — gentle warming keeps your energy flowing.
**The person:** Handles stress well but gravitates toward warmth, prefers cooked food, feels heavier in cold weather.
**Superpower:** You stay composed under pressure. Warmth turns that calm into momentum.
**Trap:** If you stay too cold for too long, you get sluggish and heavy.
**Recommended tags:** warming, supports_digestion, moves_qi
**Avoid tags:** cooling
**Starter ingredients:** Ginger, Scallion, Black Pepper, Lamb, Walnuts, Longan

### 🪫 Low Battery (Neutral + Deficient)

**TCM equivalent:** Qi Deficiency (气虚质)
**In one sentence:** Your energy tank runs low easily — gentle, predictable nourishment gives you the biggest returns.
**The person:** Gets tired more easily than peers, catches colds, sensitive to overcommitment, digestion is fragile.
**Superpower:** You're sensitive in a good way. Small changes give you big returns.
**Trap:** Overcommitting drains you. You feel it in sleep, digestion, and focus.
**Recommended tags:** supports_deficiency, supports_digestion, calms_shen
**Avoid tags:** (none — flexible type)
**Starter ingredients:** Rice, Chicken, Eggs, Sweet Potato, Mushrooms, Honey

### ⚖️ Steady Core (Neutral + Balanced)

**TCM equivalent:** Balanced Constitution (平和质)
**In one sentence:** You're the baseline healthy type — rhythm and consistency are your main levers.
**The person:** Adapts well, tolerates variety, gets thrown off mainly by chaotic schedules rather than specific foods.
**Superpower:** You adapt well. With the right ritual, you can fine-tune sleep, digestion, and energy quickly.
**Trap:** When your schedule gets chaotic, your body follows.
**Recommended tags:** supports_digestion, moves_qi
**Avoid tags:** (none — flexible type)
**Starter ingredients:** Green Tea, Rice, Vegetables, Tofu, Fish, Sesame

### 🧠 Busy Mind (Neutral + Excess)

**TCM equivalent:** Qi Stagnation (气郁质) trending toward Excess
**In one sentence:** You have plenty of energy but it gets stuck — tension, overthinking, and digestive tightness are your signals.
**The person:** High achiever, holds stress in body (jaw, shoulders), prone to irritability, may have bloating from tension rather than food.
**Superpower:** You have drive. When your flow is smooth, you're magnetic and productive.
**Trap:** You can run on tension. It looks like energy, but it costs sleep and digestion.
**Recommended tags:** moves_qi, calms_shen
**Avoid tags:** (none — flexible type)
**Starter ingredients:** Chamomile, Citrus Peel, Radish, Celery, Mint, Jasmine

### 🔥 High Flame (Warm + Balanced)

**TCM equivalent:** Warm pattern with adequate Yin (热证, 阴不虚)
**In one sentence:** You have natural spark and warmth — staying cool-headed keeps you clear and light.
**The person:** Runs warm, prefers cooler environments, good energy but can tip into restlessness with stimulants.
**Superpower:** You have natural spark. When you stay cool-headed, you feel light and clear.
**Trap:** Too much stimulation (stress, late nights, spicy/alcohol) tips you into restlessness.
**Recommended tags:** cooling, calms_shen, moves_qi
**Avoid tags:** warming
**Starter ingredients:** Cucumber, Mung Bean, Pear, Chrysanthemum, Green Tea, Watermelon

### ⚡ Overclocked (Warm + Excess)

**TCM equivalent:** Yang Excess / Damp-Heat trending (阳盛质 / 湿热质)
**In one sentence:** You run hot and intense — deliberate cooling and calming signals protect your sleep and clarity.
**The person:** Runs hot, intense personality, strong appetite, may have skin issues, sleep is often the first thing disrupted.
**Superpower:** You have intensity. When it's directed, you're powerful and sharp.
**Trap:** You can overrun your nervous system — sleep becomes the first casualty.
**Recommended tags:** cooling, calms_shen, reduces_excess
**Avoid tags:** warming
**Starter ingredients:** Mung Bean, Bitter Melon, Celery, Lotus Root, Pear, Mint

### 🏜️ Bright but Thin (Warm + Deficient)

**TCM equivalent:** Yin Deficiency (阴虚质)
**In one sentence:** You're bright and sensitive but your reserves run dry — moistening nourishment and calm evenings are your medicine.
**The person:** Runs warm but feels depleted, dry skin/lips, restless sleep, creative and perceptive, wired-tired energy pattern.
**Superpower:** You're bright and sensitive. When nourished, you're glowing and creative.
**Trap:** You can feel warm but depleted — restless sleep, dryness, and wired-tired energy.
**Recommended tags:** moistens_dryness, supports_deficiency, calms_shen
**Avoid tags:** warming
**Starter ingredients:** Pear, Honey, Sesame, Lily Bulb, Tremella, Goji Berry

---

## Part 5: Audit Summary

### What's strong

| Aspect | Assessment |
|--------|-----------|
| Two-axis primary grid (Cold/Heat × Def/Excess) | Textbook-correct use of Two of the Eight Principles |
| Modifier layer (Shen, Stagnation, Damp, Dry) | Clinically sound secondary pattern detection |
| Modifier priority order (Shen > Stagnation > Damp/Dry) | Matches real TCM triage logic |
| 5-axis vector system | Covers the most clinically relevant dimensions |
| Omission of Special/Allergic type | Correct for a lifestyle app |
| Nicknames and superpower framing | Strong UX — makes constitution theory accessible |

### What's acceptable (minor limitations)

| Aspect | Assessment | Recommendation |
|--------|-----------|----------------|
| Cold + Excess collapsed to Cold + Balanced | Rare as chronic constitution | Acceptable. Document internally. |
| Blood Stasis only partially captured | Qi Stagnation is the precursor, but not the full pattern | Consider adding 1 bruising/pain question in future |
| "Low Battery" nickname | Slightly mechanical — implies user is a device | Consider alternatives like "Quiet Reserves" |

### What's not captured (and shouldn't be)

| TCM Concept | Why it's excluded | Correct? |
|-------------|-------------------|----------|
| Tongue/pulse diagnosis | Requires in-person practitioner | Yes |
| Blood Stasis detail | Needs clinical assessment | Yes |
| Special/Allergic constitution | Can't address with food/lifestyle alone | Yes |
| Organ-specific patterns (e.g., Liver Fire, Kidney Yang Xu) | Too granular for a self-assessment quiz | Yes |

### Overall verdict

Terrain's type system is a **faithful, well-prioritized simplification** of TCM constitution theory. It captures the dimensions that matter most for daily lifestyle choices (thermal tendency, energy reserves, fluid balance, flow, mind state) while avoiding the dimensions that require clinical training to assess (pulse quality, tongue coating, organ-level differentiation).

The 2-axis + modifier architecture is arguably **cleaner than Wang Qi's flat 9-type list** because it makes the relationships between types visible. A user can see that "Low Flame" and "Cool Core" are neighbors on the grid (both cold, different energy levels) rather than treating them as unrelated categories. This aids understanding and makes the system feel coherent rather than arbitrary.

For a consumer wellness app, this is about as good as you can get without putting a TCM practitioner in the phone.
