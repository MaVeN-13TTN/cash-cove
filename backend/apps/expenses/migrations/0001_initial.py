# Generated by Django 5.1.3 on 2024-11-26 18:49

import django.core.validators
import django.db.models.deletion
from decimal import Decimal
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('budgets', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='Expense',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(help_text='Brief description of the expense', max_length=255, verbose_name='Title')),
                ('amount', models.DecimalField(decimal_places=2, max_digits=12, validators=[django.core.validators.MinValueValidator(Decimal('0.01'))], verbose_name='Amount')),
                ('category', models.CharField(choices=[('FOOD', 'Food & Dining'), ('TRANSPORT', 'Transportation'), ('HOUSING', 'Housing & Utilities'), ('HEALTHCARE', 'Healthcare'), ('ENTERTAINMENT', 'Entertainment'), ('SHOPPING', 'Shopping'), ('EDUCATION', 'Education'), ('OTHER', 'Other')], default='OTHER', max_length=100, verbose_name='Category')),
                ('date', models.DateField(verbose_name='Date')),
                ('payment_method', models.CharField(choices=[('CASH', 'Cash'), ('CREDIT_CARD', 'Credit Card'), ('DEBIT_CARD', 'Debit Card'), ('BANK_TRANSFER', 'Bank Transfer'), ('MOBILE_PAYMENT', 'Mobile Payment'), ('OTHER', 'Other')], default='CASH', max_length=50, verbose_name='Payment Method')),
                ('notes', models.TextField(blank=True, help_text='Additional details about the expense', verbose_name='Notes')),
                ('receipt_image', models.ImageField(blank=True, null=True, upload_to='receipts/%Y/%m/', verbose_name='Receipt Image')),
                ('location', models.CharField(blank=True, help_text='Where the expense was incurred', max_length=255, verbose_name='Location')),
                ('is_recurring', models.BooleanField(default=False, help_text='Whether this is a recurring expense', verbose_name='Is Recurring')),
                ('tags', models.JSONField(blank=True, default=list, help_text='Custom tags for the expense', verbose_name='Tags')),
                ('metadata', models.JSONField(blank=True, default=dict, help_text='Additional metadata for the expense', verbose_name='Metadata')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Created At')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Updated At')),
                ('budget', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='expenses', to='budgets.budget', verbose_name='Budget')),
            ],
            options={
                'verbose_name': 'Expense',
                'verbose_name_plural': 'Expenses',
                'ordering': ['-date', '-created_at'],
            },
        ),
    ]
