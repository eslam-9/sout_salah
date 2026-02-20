# Prayer Names Reference

The app uses exactly 9 prayers per day as specified. Here's the complete structure:

## 9 Required Prayers

1. **Fajr** - Dawn prayer
2. **Maghrib** - Sunset prayer  
3. **Isha** - Night prayer
4. **Taraweeh 1** - First Taraweeh section
5. **Taraweeh 2** - Second Taraweeh section
6. **Taraweeh 3** - Third Taraweeh section
7. **Taraweeh 4** - Fourth Taraweeh section
8. **Shaf** - Shaf prayer
9. **Witr** - Witr prayer

## Notes

- These exact names must be used in the database `prayer_name` field
- Each prayer can have 0 or more audio recordings
- UI must show all 9 prayers even if some have no recordings
- Empty prayers should show "No recordings yet" with upload option (if user has permission)

## Database Constraint

```sql
prayer_name TEXT NOT NULL CHECK (
  prayer_name IN ('Fajr', 'Maghrib', 'Isha', 'Taraweeh 1', 'Taraweeh 2', 'Taraweeh 3', 'Taraweeh 4', 'Shaf', 'Witr')
)
```

## Flutter Enum

```dart
enum Prayer {
  fajr('Fajr'),
  maghrib('Maghrib'),
  isha('Isha'),
  taraweeh1('Taraweeh 1'),
  taraweeh2('Taraweeh 2'),
  taraweeh3('Taraweeh 3'),
  taraweeh4('Taraweeh 4'),
  shaf('Shaf'),
  witr('Witr');

  final String displayName;
  const Prayer(this.displayName);
}
```
