# Supabase Storage Setup Guide

This guide shows how to configure Supabase Storage for audio file uploads.

## 1. Create Storage Bucket

1. Go to Supabase Dashboard → Storage
2. Click "New Bucket"
3. Bucket Settings:
   - **Name**: `recordings`
   - **Public**: ✅ Yes (for public read access)
   - **File size limit**: 50 MB (adjust as needed)
   - **Allowed MIME types**: `audio/*`

## 2. Set Bucket Policies

After creating the bucket, set up RLS policies:

### Policy 1: Public Read Access
```sql
-- Allow everyone to download/view recordings
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'recordings' );
```

### Policy 2: Authenticated Upload
```sql
-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'recordings' 
  AND auth.uid() IS NOT NULL
);
```

### Policy 3: Users Can Delete Own Files
```sql
-- Users can delete their own uploads
CREATE POLICY "Users can delete own files"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'recordings' 
  AND auth.uid() = owner
);
```

## 3. Folder Structure

Organize files in the bucket:
```
recordings/
  ├── {mosque_id}/
  │   ├── day_1/
  │   │   ├── fajr/
  │   │   │   ├── {timestamp}_{sheikh_name}.mp3
  │   │   ├── maghrib/
  │   │   ├── isha/
  │   │   ├── taraweeh_1/
  │   │   └── ...
  │   ├── day_2/
  │   └── ...
```

## 4. File Naming Convention

```
{timestamp}_{prayername}_{sheikh_name_sanitized}.{extension}

Example:
1707532800_fajr_sheikh_ahmed.mp3
```

## 5. Flutter Integration

### Upload File
```dart
final file = File(pickedFile.path);
final fileName = '${DateTime.now().millisecondsSinceEpoch}_${prayerName}_${sheikhName}.mp3';
final path = '$mosqueId/day_$dayNumber/$prayerName/$fileName';

await supabase.storage
  .from('recordings')
  .upload(path, file);

// Get public URL
final publicUrl = supabase.storage
  .from('recordings')
  .getPublicUrl(path);
```

### Delete File
```dart
await supabase.storage
  .from('recordings')
  .remove([filePath]);
```

## 6. Size Limits

Configure in Supabase Dashboard → Storage → Settings:
- **Max file size**: 50 MB (recommended for audio)
- **Total storage**: Check your plan limits

## 7. MIME Types

Allowed audio formats:
- `audio/mpeg` (.mp3)
- `audio/mp4` (.m4a)
- `audio/wav` (.wav)
- `audio/ogg` (.ogg)

## 8. Testing

Manual test in Supabase Dashboard:
1. Go to Storage → recordings bucket
2. Upload a test .mp3 file
3. Verify public URL works
4. Try deleting the file
5. Check RLS policies are working

## 9. Security Notes

- ✅ Public read is OK - recordings should be accessible to everyone
- ✅ Authenticated write ensures only logged-in users can upload
- ✅ Database RLS policies enforce who can insert recording metadata
- ⚠️ Consider adding virus scanning in production
- ⚠️ Monitor storage usage to avoid quota issues

## 10. Troubleshooting

### Upload Fails
- Check user is authenticated
- Verify file size is under limit
- Check MIME type is allowed

### Can't Access File
- Verify bucket is public
- Check RLS policies are created
- Confirm file path is correct

### Delete Fails
- Check user owns the file
- Verify storage.objects policies exist
