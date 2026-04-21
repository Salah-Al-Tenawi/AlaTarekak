# Word Templates

Place your Word template files (.docx) here with the following names:

1. `template_warid_manateq.docx`
2. `template_warid_wizara.docx`
3. `template_sader_wizara.docx`

## Template Placeholders

Each template must include these placeholders:

- `{{number}}` - Document number
- `{{date}}` - Document date
- `{{region}}` - Region name
- `{{subject}}` - Document subject
- `{{content}}` - Main content

## Example Template Structure

```
=======================================================
                وزارة الداخلية
              قسم الأرشيف الإلكتروني
=======================================================

رقم الوثيقة: {{number}}
التاريخ: {{date}}
المنطقة: {{region}}

الموضوع: {{subject}}

-------------------------------------------------------

{{content}}

-------------------------------------------------------

                     إدارة الأرشيف
```

See TEMPLATE_GUIDE.md in the root directory for detailed instructions.
