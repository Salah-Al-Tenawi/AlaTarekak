# Excel Files (Optional Backups)

This folder can contain backup copies of your Excel files.

The actual Excel files used by the system should be placed on your network share:

```
\\YOUR_COMPUTER\SharedArchive\warid_manateq.xlsx
\\YOUR_COMPUTER\SharedArchive\warid_wizara.xlsx
\\YOUR_COMPUTER\SharedArchive\sader_wizara.xlsx
```

## Excel File Structure

Each Excel file should have the following columns in the first row:

| Column | Header (Arabic) | Description |
|--------|----------------|-------------|
| A | الرقم | Document number |
| B | التاريخ | Date |
| C | المنطقة | Region |
| D | الموضوع | Subject |
| E | الملف | File hyperlink |

The system will automatically append new rows with data when documents are saved.
