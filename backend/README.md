# Budget Tracker Backend

A Django-based REST API backend for the Budget Tracker application, providing comprehensive financial management features including expense tracking, budget planning, and shared expense management.

## Project Structure

```
backend/
├── apps/                    # Application modules
│   ├── analytics/          # Analytics and reporting
│   ├── budgets/            # Budget management
│   ├── expenses/           # Expense tracking
│   ├── notifications/      # User notifications
│   ├── shared_expenses/    # Shared expense management
│   └── users/              # User management
├── core/                   # Core project settings
├── docker/                 # Docker configuration
│   ├── nginx/             # Nginx configuration
│   ├── Dockerfile         # Main Dockerfile
│   └── docker-compose.yml # Docker compose configuration
├── requirements/           # Python dependencies
│   ├── base.txt           # Base requirements
│   ├── local.txt          # Local development requirements
│   └── production.txt     # Production requirements
├── scripts/               # Utility scripts
├── utils/                 # Helper utilities
├── static/                # Static files
└── media/                 # User-uploaded media
```

## Features

- User Authentication & Authorization
- Expense Tracking & Management
- Budget Planning & Monitoring
- Shared Expense Management
- Analytics & Reporting
- Real-time Notifications
- File Upload Support
- API Documentation

## Prerequisites

- Python 3.8+
- PostgreSQL
- Redis (for caching and async tasks)
- Docker & Docker Compose (optional)

## Setup

1. Create a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # Linux/macOS
   # or
   .\venv\Scripts\activate  # Windows
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements/local.txt  # for development
   # or
   pip install -r requirements/production.txt  # for production
   ```

3. Environment Variables:
   - Copy `.env.example` to `.env`
   - Update the variables in `.env` with your configuration

4. Database Setup:
   ```bash
   python manage.py migrate
   python manage.py createsuperuser
   ```

5. Run the development server:
   ```bash
   python manage.py runserver
   ```

## Docker Deployment

1. Build and run with Docker Compose:
   ```bash
   docker-compose -f docker/docker-compose.yml up --build
   ```

2. For production deployment:
   ```bash
   docker-compose -f docker/docker-compose.yml -f docker/docker-compose.prod.yml up -d
   ```

## API Documentation

API documentation is available at:
- Development: `http://localhost:8000/api/docs/`
- Production: `https://api.budgettracker.com/docs/`

## Testing

Run tests with:
```bash
python manage.py test
```

For coverage report:
```bash
coverage run manage.py test
coverage report
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## Security

- All endpoints are secured with JWT authentication
- Rate limiting is implemented
- Input validation and sanitization
- CORS configuration
- Regular security updates

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, email support@budgettracker.com or create an issue in the repository.