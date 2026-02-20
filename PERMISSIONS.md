# Role-Based Permissions Matrix

This document defines EXACTLY what each role can and cannot do.

## Roles

1. **Admin** - Creator of a mosque (auto-assigned on creation)
2. **Publisher** - Assigned by admin, can upload to specific mosque
3. **Normal User** - Authenticated user with view-only access
4. **Guest** - Unauthenticated user with view-only access

## Permissions by Feature

### Mosque Management

| Action | Admin (Own Mosque) | Publisher | Normal User | Guest |
|--------|-------------------|-----------|-------------|-------|
| View mosques | ✅ | ✅ | ✅ | ✅ |
| Create mosque | ✅ | ✅ | ✅ | ❌ |
| Edit mosque details | ✅ | ❌ | ❌ | ❌ |
| Delete mosque | ✅ | ❌ | ❌ | ❌ |
| Add publishers | ✅ | ❌ | ❌ | ❌ |
| Remove publishers | ✅ | ❌ | ❌ | ❌ |

### Audio Recordings

| Action | Admin (Own Mosque) | Publisher (Assigned) | Normal User | Guest |
|--------|-------------------|---------------------|-------------|-------|
| View/Listen recordings | ✅ | ✅ | ✅ | ✅ |
| Upload recording | ✅ | ✅ | ❌ | ❌ |
| Delete own recording | ✅ | ✅ | ❌ | ❌ |
| Delete any recording | ✅ | ❌ | ❌ | ❌ |

### Calendar & Days

| Action | Admin | Publisher | Normal User | Guest |
|--------|-------|-----------|-------------|-------|
| View calendar | ✅ | ✅ | ✅ | ✅ |
| View day details | ✅ | ✅ | ✅ | ✅ |
| View prayers | ✅ | ✅ | ✅ | ✅ |

## Role Scope Rules

### Admin
- Admin role is **per-mosque**
- Being admin of Mosque A gives NO permissions for Mosque B
- Admin can ONLY manage their own mosque
- Multiple people can create mosques (each becomes admin of their own)

### Publisher
- Publisher role is **per-mosque**
- A user can be publisher of multiple mosques
- Publisher can ONLY upload to mosques they're assigned to
- Publisher CANNOT upload to other mosques
- Publisher can ONLY delete their own recordings, NOT others'

### Normal User
- Read-only access to everything
- Can create their own mosque (becomes admin of it)
- Cannot upload or delete recordings in others' mosques

### Guest
- Same as Normal User but cannot create mosques
- Must authenticate to create mosque or become publisher

## Permission Enforcement

### Database Level (RLS Policies)
```sql
-- Admins can delete any recording in their mosque
EXISTS (
  SELECT 1 FROM mosques 
  WHERE id = recordings.mosque_id 
  AND admin_id = auth.uid()
)

-- Publishers can delete only their own recordings
publisher_id = auth.uid()

-- Publishers can upload to assigned mosques
EXISTS (
  SELECT 1 FROM mosque_publishers 
  WHERE mosque_id = recordings.mosque_id 
  AND publisher_id = auth.uid()
)
```

### Application Level (UI)
```dart
// Show upload button
if (isAdmin || isPublisher) {
  FloatingActionButton(
    onPressed: () => navigateToUpload(),
    child: Icon(Icons.upload),
  )
}

// Show delete button
if (isAdmin || (isPublisher && recording.publisherId == currentUserId)) {
  IconButton(
    icon: Icon(Icons.delete),
    onPressed: () => deleteRecording(recording.id),
  )
}
```

## Critical Rules

1. **No user can manage mosques unless they are the admin**
2. **No publisher can manage other mosques**
3. **No normal user can upload**
4. **No guest can upload**
5. **Each mosque is isolated** - permissions don't cross mosque boundaries
6. **Roles apply per-mosque, not globally**

## Examples

### Example 1: User creates Mosque A
- User becomes Admin of Mosque A
- User can upload to Mosque A
- User can delete any recording in Mosque A
- User can add publishers to Mosque A
- User has NO permissions for Mosque B (unless also admin/publisher there)

### Example 2: User is Publisher in Mosque A
- User can upload to Mosque A
- User can delete ONLY their own recordings in Mosque A
- User CANNOT delete others' recordings in Mosque A
- User CANNOT add/remove publishers in Mosque A
- User CANNOT upload to Mosque B (unless also publisher there)

### Example 3: Normal User
- User can view all mosques
- User can listen to all recordings
- User can create their own mosque (becomes admin of it)
- User CANNOT upload to any existing mosque
- User CANNOT delete any recordings

### Example 4: Guest
- Same as Normal User
- CANNOT create mosques (must sign up first)
