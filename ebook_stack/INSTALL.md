# E-Book Stack installation & configuration

## Initial Setup
1. Configure your `.env` file with required variables
2. Ensure Download Stack is running (Prowlarr, qBittorrent, etc.)
3. Create required directories for e-book storage
4. Set up proper permissions for e-book files
5. Migrate existing Calibre library if applicable

## Configuration

### Calibre
- **Initial Setup**: Access via port 8080 (KasmVNC interface)
- **Library Location**: Configure library at `/data/media/books`
- **Content Server**: Enable on port 8081 for Readarr integration
- **Existing Library**: Import existing library before configuring Readarr
- **Desktop Interface**: Full Calibre desktop experience via web browser
- **Conversions**: Built-in support for multiple e-book formats

### Calibre-Web
- **Initial Login**: Default credentials are `admin:admin123`
- **Library Path**: Point to Calibre library at `/data/media/books`
- **User Management**: Set up user accounts and permissions
- **Email Configuration**: Configure SMTP for sending books to devices
- **Upload Permissions**: Configure which users can upload books
- **Reading Interface**: Built-in e-book reader for web browsers

### Readarr
- **Root Folders**: Configure `/data/media/books` as root folder
- **Calibre Integration**: Connect to Calibre Content Server on port 8081
- **Quality Profiles**: Set up quality preferences for different formats
- **Metadata Profiles**: Configure metadata sources and preferences
- **Download Client**: Connect to qBittorrent from Download Stack
- **Indexers**: Connect to Prowlarr for book sources
- **Import Lists**: Configure Goodreads or other book discovery lists

## Troubleshooting

### Calibre Issues
- Check VNC connectivity if desktop interface not loading
- Verify library permissions and ownership
- Ensure Content Server is enabled and accessible
- Test library database integrity

### Calibre-Web Issues
- Verify library path points to correct Calibre database
- Check user permissions for library access
- Test SMTP configuration for email delivery
- Monitor upload directory permissions

### Readarr Issues
- Verify Calibre Content Server connectivity
- Check download client configuration
- Test indexer connections through Prowlarr
- Monitor import process for metadata issues

### Integration Problems
- Ensure Readarr has exclusive control over library
- Check API connectivity between services
- Verify file permissions across all services
- Test hardlink settings (disabled recommended)

## Configuration Details

### Calibre Content Server
Enable in Calibre preferences:
1. Open Calibre desktop interface
2. Go to Preferences → Sharing over the net
3. Enable "Start Content server automatically"
4. Set port to 8081
5. Configure access permissions

### Readarr-Calibre Integration
1. In Readarr, go to Settings → Media Management
2. Enable "Use Calibre"
3. Set Calibre Host: `calibre:8081`
4. Configure output format preferences
5. Test connection

### Quality Profiles
Recommended e-book format preferences:
- **Preferred**: EPUB, MOBI
- **Acceptable**: PDF, AZW3
- **Avoid**: TXT, HTML (unless necessary)

### Metadata Configuration
- **Primary Source**: Goodreads, Amazon
- **Cover Art**: Download high-quality covers
- **Author Names**: Standardize formatting
- **Series Information**: Enable series detection

## File Structure
Recommended e-book organization:
```
/data/media/books/
├── Author Name/
│   ├── Series Name/
│   │   ├── Book 1 - Title (Year)/
│   │   │   ├── cover.jpg
│   │   │   ├── metadata.opf
│   │   │   └── Book Title.epub
│   │   └── Book 2 - Title (Year)/
│   └── Standalone Books/
└── Calibre Library/
    └── metadata.db
```

## Important Notes
- **Database Control**: Only Readarr should modify the Calibre database
- **No Hardlinks**: Disable hardlinks in download client for e-books
- **Backup Strategy**: Regularly backup Calibre database and metadata
- **Format Conversion**: Let Calibre handle format conversions automatically
- **User Access**: Calibre-Web provides multi-user access to single library
