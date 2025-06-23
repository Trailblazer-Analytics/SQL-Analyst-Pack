# Chinook Database Data Dictionary

The Chinook database represents a digital media store, including tables for artists, albums, media tracks, invoices, and customers.

## 📊 **Database Overview**

- **Database Type**: Sample/Demo Database
- **Domain**: Digital Music Store
- **Records**: ~77,000 total records across all tables
- **Time Period**: 2009-2013
- **Geographic Coverage**: Global (multiple countries)

## 🗂️ **Table Relationships**

```
Artists (1) ──→ (M) Albums (1) ──→ (M) Tracks (M) ──→ (M) InvoiceItems (M) ──→ (1) Invoices (M) ──→ (1) Customers
                                    │                                                  │
                                    └─→ (M) PlaylistTrack (M) ──→ (1) Playlists      └─→ (1) Employees
                                    │
                                    └─→ (1) MediaTypes
                                    │
                                    └─→ (1) Genres
```

## 📋 **Tables and Columns**

### **artists**
Stores information about music artists and bands.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| ArtistId | INTEGER | Unique identifier | PRIMARY KEY, NOT NULL |
| Name | VARCHAR(120) | Artist or band name | NULL allowed |

**Sample Data**: AC/DC, Accept, Aerosmith, Alanis Morissette, Alice In Chains...

---

### **albums**
Contains album information linked to artists.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| AlbumId | INTEGER | Unique identifier | PRIMARY KEY, NOT NULL |
| Title | VARCHAR(160) | Album title | NOT NULL |
| ArtistId | INTEGER | Reference to artist | FOREIGN KEY (artists.ArtistId), NOT NULL |

**Sample Data**: "For Those About To Rock We Salute You", "Balls to the Wall", "Restless and Wild"...

---

### **tracks**
Individual songs/tracks with detailed metadata.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| TrackId | INTEGER | Unique identifier | PRIMARY KEY, NOT NULL |
| Name | VARCHAR(200) | Track/song title | NOT NULL |
| AlbumId | INTEGER | Reference to album | FOREIGN KEY (albums.AlbumId) |
| MediaTypeId | INTEGER | Media format reference | FOREIGN KEY (media_types.MediaTypeId), NOT NULL |
| GenreId | INTEGER | Music genre reference | FOREIGN KEY (genres.GenreId) |
| Composer | VARCHAR(220) | Song composer(s) | NULL allowed |
| Milliseconds | INTEGER | Track length in milliseconds | NOT NULL |
| Bytes | INTEGER | File size in bytes | NULL allowed |
| UnitPrice | DECIMAL(10,2) | Price per track | NOT NULL |

**Sample Data**: "For Those About To Rock (We Salute You)", "Put The Finger On You", "Let's Get It Up"...

---

### **media_types**
Different media formats available.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| MediaTypeId | INTEGER | Unique identifier | PRIMARY KEY, NOT NULL |
| Name | VARCHAR(120) | Media format name | NULL allowed |

**Sample Data**: MPEG audio file, Protected AAC audio file, Protected MPEG-4 video file, Purchased AAC audio file, AAC audio file

---

### **genres**
Music genre classifications.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| GenreId | INTEGER | Unique identifier | PRIMARY KEY, NOT NULL |
| Name | VARCHAR(120) | Genre name | NULL allowed |

**Sample Data**: Rock, Jazz, Metal, Alternative & Punk, Rock And Roll, Blues, Latin, Reggae, Pop, Soundtrack...

---

### **playlists**
User-created music playlists.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| PlaylistId | INTEGER | Unique identifier | PRIMARY KEY, NOT NULL |
| Name | VARCHAR(120) | Playlist name | NULL allowed |

**Sample Data**: Music, Movies, TV Shows, Audiobooks, 90's Music, Audiobooks, Movies, Music, Music Videos...

---

### **playlist_track**
Many-to-many relationship between playlists and tracks.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| PlaylistId | INTEGER | Reference to playlist | FOREIGN KEY (playlists.PlaylistId), NOT NULL |
| TrackId | INTEGER | Reference to track | FOREIGN KEY (tracks.TrackId), NOT NULL |

**Primary Key**: Composite (PlaylistId, TrackId)

---

### **customers**
Customer information and contact details.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| CustomerId | INTEGER | Unique identifier | PRIMARY KEY, NOT NULL |
| FirstName | VARCHAR(40) | Customer first name | NOT NULL |
| LastName | VARCHAR(20) | Customer last name | NOT NULL |
| Company | VARCHAR(80) | Company name | NULL allowed |
| Address | VARCHAR(70) | Street address | NULL allowed |
| City | VARCHAR(40) | City | NULL allowed |
| State | VARCHAR(40) | State/Province | NULL allowed |
| Country | VARCHAR(40) | Country | NULL allowed |
| PostalCode | VARCHAR(10) | Postal/ZIP code | NULL allowed |
| Phone | VARCHAR(24) | Phone number | NULL allowed |
| Fax | VARCHAR(24) | Fax number | NULL allowed |
| Email | VARCHAR(60) | Email address | NOT NULL |
| SupportRepId | INTEGER | Support representative | FOREIGN KEY (employees.EmployeeId) |

**Geographic Distribution**: 24 countries represented, with concentrations in USA, Canada, Brazil, France, Germany

---

### **employees**
Company employee information and hierarchy.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| EmployeeId | INTEGER | Unique identifier | PRIMARY KEY, NOT NULL |
| LastName | VARCHAR(20) | Employee last name | NOT NULL |
| FirstName | VARCHAR(20) | Employee first name | NOT NULL |
| Title | VARCHAR(30) | Job title | NULL allowed |
| ReportsTo | INTEGER | Manager reference | FOREIGN KEY (employees.EmployeeId) |
| BirthDate | DATETIME | Date of birth | NULL allowed |
| HireDate | DATETIME | Date hired | NULL allowed |
| Address | VARCHAR(70) | Street address | NULL allowed |
| City | VARCHAR(40) | City | NULL allowed |
| State | VARCHAR(40) | State/Province | NULL allowed |
| Country | VARCHAR(40) | Country | NULL allowed |
| PostalCode | VARCHAR(10) | Postal/ZIP code | NULL allowed |
| Phone | VARCHAR(24) | Phone number | NULL allowed |
| Fax | VARCHAR(24) | Fax number | NULL allowed |
| Email | VARCHAR(60) | Email address | NULL allowed |

**Sample Titles**: General Manager, Sales Manager, Sales Support Agent, IT Manager, IT Staff

---

### **invoices**
Customer purchase transactions.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| InvoiceId | INTEGER | Unique identifier | PRIMARY KEY, NOT NULL |
| CustomerId | INTEGER | Reference to customer | FOREIGN KEY (customers.CustomerId), NOT NULL |
| InvoiceDate | DATETIME | Date of purchase | NOT NULL |
| BillingAddress | VARCHAR(70) | Billing street address | NULL allowed |
| BillingCity | VARCHAR(40) | Billing city | NULL allowed |
| BillingState | VARCHAR(40) | Billing state/province | NULL allowed |
| BillingCountry | VARCHAR(40) | Billing country | NULL allowed |
| BillingPostalCode | VARCHAR(10) | Billing postal code | NULL allowed |
| Total | DECIMAL(10,2) | Total invoice amount | NOT NULL |

**Date Range**: 2009-01-01 to 2013-12-22
**Invoice Count**: 412 total invoices

---

### **invoice_items**
Individual line items within invoices.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| InvoiceLineId | INTEGER | Unique identifier | PRIMARY KEY, NOT NULL |
| InvoiceId | INTEGER | Reference to invoice | FOREIGN KEY (invoices.InvoiceId), NOT NULL |
| TrackId | INTEGER | Reference to track | FOREIGN KEY (tracks.TrackId), NOT NULL |
| UnitPrice | DECIMAL(10,2) | Price per unit | NOT NULL |
| Quantity | INTEGER | Number of units purchased | NOT NULL |

**Line Items**: 2,240 total line items across all invoices

## 📈 **Key Business Metrics**

### **Sales Data**
- **Total Revenue**: ~$37,000 across all invoices
- **Average Invoice**: ~$90
- **Most Expensive Track**: $1.99
- **Least Expensive Track**: $0.99

### **Catalog Size**
- **Artists**: 275 unique artists
- **Albums**: 347 albums
- **Tracks**: 3,503 individual tracks
- **Genres**: 25 different genres
- **Playlists**: 18 user-created playlists

### **Customer Base**
- **Total Customers**: 59 customers
- **Countries Served**: 24 countries
- **Active Period**: 2009-2013 (5 years)

## 🎯 **Common Analysis Use Cases**

This database is perfect for learning:

1. **Sales Analysis**: Revenue trends, top customers, geographic analysis
2. **Product Analysis**: Best-selling tracks, popular genres, album performance
3. **Customer Segmentation**: Purchase behavior, geographic distribution, loyalty analysis
4. **Inventory Management**: Track catalog analysis, media type preferences
5. **Employee Performance**: Sales rep effectiveness, customer assignments
6. **Time Series Analysis**: Monthly/yearly trends, seasonal patterns

## ⚠️ **Data Quality Notes**

- Some **NULL values** exist in optional fields (Company, Address, Phone, etc.)
- **Date consistency**: All dates follow ISO format (YYYY-MM-DD HH:MM:SS)
- **Currency**: All prices in USD
- **Encoding**: UTF-8 for international characters in artist/track names
- **Referential Integrity**: All foreign key relationships are properly maintained

---

*This data dictionary serves as your reference guide when writing queries against the Chinook database. Use it to understand table relationships and plan your analytical queries.*
