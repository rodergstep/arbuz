<!-- Template for design §6 (Runtime view), embedded inline in sad.md. One `### <flow>` block per critical flow. -->
<!-- Participants are REAL names from the architecture map: the child/parent, scenes, UI, autoloads, user:// files. -->
<!-- Message text is in plain words; no `;` in messages or notes (Mermaid treats it as a separator). -->

### <flow name> (US-NN, AC-NN…)

```mermaid
sequenceDiagram
    autonumber
    actor Child
    participant UI as <Scene/UI node, e.g. BakeryCards>
    participant IS as InteractionSystem
    participant LT as LearningTracker
    participant SS as SaveSystem
    participant AD as AudioDirector

    Note over Child,UI: Precondition: <state from the spec>
    Child->>UI: taps a card
    UI->>IS: report_pick(word_id, target_id)
    IS->>LT: word_answered(word_id, correct)
    LT->>SS: request_save()
    SS-->>LT: saved
    IS-->>UI: pick_resolved(correct)
    alt correct
        UI->>AD: play(sfx.success_soft)
        UI->>AD: say(vo.word.<id>)
    else wrong
        UI->>AD: say(vo.word.<tapped>)
        Note over UI: card wiggles, hint ladder restarts
    end
    Note over Child,UI: Postcondition: <state guaranteed after, from the spec>
```

### <idle / interruption flow name>

```mermaid
sequenceDiagram
    autonumber
    actor Child
    participant UI as <Scene/UI>
    participant HL as <HintLadder>
    participant ST as SessionTimer

    Note over Child,UI: Child stops interacting
    UI->>HL: idle_started()
    HL-->>UI: show hint level 1 after N s
    HL-->>UI: show hint level 2 after N s
    opt session limit reached
        ST-->>UI: session_ending()
        Note over UI: soft goodbye scene, progress saved
    end
```

<!-- After the flows, a coverage table: every §5 AC → flow / branch, or N/A with a reason. -->

| AC | Shown by |
|---|---|
| AC-01 | <flow> step <n> |
