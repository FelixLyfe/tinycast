# Clipboard history

Cliiippo stores text up to 32,000 characters and PNG image data. Sensitive pasteboard markers and
copies from excluded bundle IDs are ignored. The list supports full-text search, text/image/link/email
filters, pinning, source-app metadata, removal, and retention pruning.

Internal copy and paste writes carry `io.github.felixlyfe.cliiippo.internal`, so polling does not
recapture them. Pinned rows are exempt from age pruning. Clear History removes rows and owned image
files after confirmation.

The store is SQLite-backed under Application Support. Image paths in the database always point to
files owned by the current Cliiippo bundle channel.
