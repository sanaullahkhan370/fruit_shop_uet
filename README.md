# UET Shops

Flutter application for customers, shop admins and the UET Shops super admin.

## Run locally

Start the backend on port 5000, then run:

### Chrome
`flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000/api`

### Android emulator
`flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api`

For production, replace the URL with the deployed HTTPS backend URL.
