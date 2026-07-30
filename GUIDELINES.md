# Project Coding Guidelines

## Code Quality Standards

### Pattern Recognition
- Identify repetitive patterns (3+ occurrences)
- Count repetitions before implementing similar code
- Look for opportunities to extract common behavior
            
### Generic Abstractions
- Use generics and protocols for type-safe reuse
- Apply protocol constraints: `<T: Protocol>`
- Extract similar logic into reusable functions

### SwiftUI Best Practices
- Use `@ViewBuilder` for generic view functions
- Leverage protocol constraints for type safety
- Prefer composition over repetition

### Refactoring Criteria
**Refactor when:**
- Same pattern appears 3+ times
- Logic is identical, only types/values differ
- Changes would require updating multiple places

**Don't refactor when:**
- Pattern only appears 1-2 times
- Logic is actually different between instances
- Abstraction would make code harder to understand

### Naming Conventions
- `collectionCell<T>` for collection display logic
- `createNew<T>` for factory creation
- `edit<T>` for editing operations

### Quality Checklist
Before accepting any code, verify:
- [ ] Reduces repetition
- [ ] More maintainable
- [ ] Maintains type safety
- [ ] Still readable
- [ ] Appropriate protocol constraints
