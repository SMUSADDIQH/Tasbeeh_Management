# Android release signing

1. Create a secure upload keystore outside version control.
2. Copy `key.properties.example` to `key.properties`.
3. Replace every placeholder with the upload-key values.
4. Keep `key.properties` and the keystore private.

When `key.properties` is absent, local release verification uses the debug key.
Production store uploads must use the configured upload key.
