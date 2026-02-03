from flask import Blueprint, request, session, render_template, url_for, redirect, flash, jsonify

bp = Blueprint('samples', __name__)

@bp.route('/activity', methods=['GET'])
def activity():
    return render_template('samples/activity.html')

@bp.route('/apps-calendar', methods=['GET'])
def apps_calendar():
    return render_template('samples/apps-calendar.html')

@bp.route('/apps-chat', methods=['GET'])
def apps_chat():
    return render_template('samples/apps-chat.html')

@bp.route('/apps-contacts', methods=['GET'])
def apps_contacts():
    return render_template('samples/apps-contacts.html')

@bp.route('/apps-email', methods=['GET'])
def apps_email():
    return render_template('samples/apps-email.html')

@bp.route('/apps-file-manager', methods=['GET'])
def apps_file_manager():
    return render_template('samples/apps-file-manager.html')

@bp.route('/apps-kanban', methods=['GET'])
def apps_kanban():
    return render_template('samples/apps-kanban.html')

@bp.route('/apps-support', methods=['GET'])
def apps_support():
    return render_template('samples/apps-support.html')

@bp.route('/apps-todo', methods=['GET'])
def apps_todo():
    return render_template('samples/apps-todo.html')

@bp.route('/auth-forgot-password', methods=['GET'])
def auth_forgot_password():
    return render_template('samples/auth-forgot-password.html')

@bp.route('/auth-lock-screen', methods=['GET'])
def auth_lock_screen():
    return render_template('samples/auth-lock-screen.html')

@bp.route('/auth-login', methods=['GET'])
def auth_login():
    return render_template('samples/auth-login.html')

@bp.route('/auth-register', methods=['GET'])
def auth_register():
    return render_template('samples/auth-register.html')

@bp.route('/auth-reset-password', methods=['GET'])
def auth_reset_password():
    return render_template('samples/auth-reset-password.html')

@bp.route('/auth-two-factor', methods=['GET'])
def auth_two_factor():
    return render_template('samples/auth-two-factor.html')

@bp.route('/auth-verify-email', methods=['GET'])
def auth_verify_email():
    return render_template('samples/auth-verify-email.html')

@bp.route('/blank', methods=['GET'])
def blank():
    return render_template('samples/blank.html')

@bp.route('/charts-apexcharts', methods=['GET'])
def charts_apexcharts():
    return render_template('samples/charts-apexcharts.html')

@bp.route('/charts-chartjs', methods=['GET'])
def charts_chartjs():
    return render_template('samples/charts-chartjs.html')

@bp.route('/charts-echarts', methods=['GET'])
def charts_echarts():
    return render_template('samples/charts-echarts.html')

@bp.route('/components-accordion', methods=['GET'])
def components_accordion():
    return render_template('samples/components-accordion.html')

@bp.route('/components-alerts', methods=['GET'])
def components_alerts():
    return render_template('samples/components-alerts.html')

@bp.route('/components-badges', methods=['GET'])
def components_badges():
    return render_template('samples/components-badges.html')

@bp.route('/components-breadcrumbs', methods=['GET'])
def components_breadcrumbs():
    return render_template('samples/components-breadcrumbs.html')

@bp.route('/components-buttons', methods=['GET'])
def components_buttons():
    return render_template('samples/components-buttons.html')

@bp.route('/components-cards', methods=['GET'])
def components_cards():
    return render_template('samples/components-cards.html')

@bp.route('/components-carousel', methods=['GET'])
def components_carousel():
    return render_template('samples/components-carousel.html')

@bp.route('/components-dropdowns', methods=['GET'])
def components_dropdowns():
    return render_template('samples/components-dropdowns.html')

@bp.route('/components-list-group', methods=['GET'])
def components_list_group():
    return render_template('samples/components-list-group.html')

@bp.route('/components-modal', methods=['GET'])
def components_modal():
    return render_template('samples/components-modal.html')

@bp.route('/components-nav-tabs', methods=['GET'])
def components_nav_tabs():
    return render_template('samples/components-nav-tabs.html')

@bp.route('/components-offcanvas', methods=['GET'])
def components_offcanvas():
    return render_template('samples/components-offcanvas.html')

@bp.route('/components-pagination', methods=['GET'])
def components_pagination():
    return render_template('samples/components-pagination.html')

@bp.route('/components-popovers', methods=['GET'])
def components_popovers():
    return render_template('samples/components-popovers.html')

@bp.route('/components-progress', methods=['GET'])
def components_progress():
    return render_template('samples/components-progress.html')

@bp.route('/components-spinners', methods=['GET'])
def components_spinners():
    return render_template('samples/components-spinners.html')

@bp.route('/components-toasts', methods=['GET'])
def components_toasts():
    return render_template('samples/components-toasts.html')

@bp.route('/components-tooltips', methods=['GET'])
def components_tooltips():
    return render_template('samples/components-tooltips.html')

@bp.route('/contact', methods=['GET'])
def contact():
    return render_template('samples/contact.html')

@bp.route('/dashboard-sales', methods=['GET'])
def dashboard_sales():
    return render_template('samples/dashboard-sales.html')

@bp.route('/dashboard-analytics', methods=['GET'])
def dashboard_analytics():
    return render_template('samples/dashboard-analytics.html')

@bp.route('/dashboard-crm', methods=['GET'])
def dashboard_crm():
    return render_template('samples/dashboard-crm.html')

@bp.route('/dashboard-finance', methods=['GET'])
def dashboard_finance():
    return render_template('samples/dashboard-finance.html')

@bp.route('/dashboard-marketing', methods=['GET'])
def dashboard_marketing():
    return render_template('samples/dashboard-marketing.html')

@bp.route('/dashboard-projects', methods=['GET'])
def dashboard_projects():
    return render_template('samples/dashboard-projects.html')

@bp.route('/error-403', methods=['GET'])
def error_403():
    return render_template('samples/error-403.html')

@bp.route('/error-404', methods=['GET'])
def error_404():
    return render_template('samples/error-404.html')

@bp.route('/error-500', methods=['GET'])
def error_500():
    return render_template('samples/error-500.html')

@bp.route('/error-maintenance', methods=['GET'])
def error_maintenance():
    return render_template('samples/error-maintenance.html')

@bp.route('/faq', methods=['GET'])
def faq():
    return render_template('samples/faq.html')

@bp.route('/forms-advanced', methods=['GET'])
def forms_advanced():
    return render_template('samples/forms-advanced.html')

@bp.route('/forms-wizard', methods=['GET'])
def forms_wizard():
    return render_template('samples/forms-wizard.html')

@bp.route('/forms-editors', methods=['GET'])
def forms_editors():
    return render_template('samples/forms-editors.html')

@bp.route('/forms-elements', methods=['GET'])
def forms_elements():
    return render_template('samples/forms-elements.html')

@bp.route('/forms-layouts', methods=['GET'])
def forms_layouts():
    return render_template('samples/forms-layouts.html')

@bp.route('/forms-upload', methods=['GET'])
def forms_upload():
    return render_template('samples/forms-upload.html')

@bp.route('/forms-select', methods=['GET'])
def forms_select():
    return render_template('samples/forms-select.html')

@bp.route('/forms-validation', methods=['GET'])
def forms_validation():
    return render_template('samples/forms-validation.html')

@bp.route('/forms-pickers', methods=['GET'])
def forms_pickers():
    return render_template('samples/forms-pickers.html')

@bp.route('/icons-bootstrap', methods=['GET'])
def icons_bootstrap():
    return render_template('samples/icons-bootstrap.html')

@bp.route('/icons-fontawesome', methods=['GET'])
def icons_fontawesome():
    return render_template('samples/icons-fontawesome.html')

@bp.route('/icons-lucide', methods=['GET'])
def icons_lucide():
    return render_template('samples/icons-lucide.html')

@bp.route('/icons-phosphor', methods=['GET'])
def icons_phosphor():
    return render_template('samples/icons-phosphor.html')

@bp.route('/icons-remixicon', methods=['GET'])
def icons_remixicon():
    return render_template('samples/icons-remixicon.html')

@bp.route('/index', methods=['GET'])
def index():
    return render_template('samples/index.html')

@bp.route('/invoice', methods=['GET'])
def invoice():
    return render_template('samples/invoice.html')

@bp.route('/invoice-list', methods=['GET'])
def invoice_list():
    return render_template('samples/invoice-list.html')

@bp.route('/notifications', methods=['GET'])
def notifications():
    return render_template('samples/notifications.html')

@bp.route('/pricing', methods=['GET'])
def pricing():
    return render_template('samples/pricing.html')

@bp.route('/profile', methods=['GET'])
def profile():
    return render_template('samples/profile.html')

@bp.route('/roles', methods=['GET'])
def roles():
    return render_template('samples/roles.html')

@bp.route('/search-results', methods=['GET'])
def search_results():
    return render_template('samples/search-results.html')

@bp.route('/settings', methods=['GET'])
def settings():
    return render_template('samples/settings.html')

@bp.route('/tables-basic', methods=['GET'])
def tables_basic():
    return render_template('samples/tables-basic.html')

@bp.route('/tables-datatables', methods=['GET'])
def tables_datatables():
    return render_template('samples/tables-datatables.html')

@bp.route('/tables-responsive', methods=['GET'])
def tables_responsive():
    return render_template('samples/tables-responsive.html')

@bp.route('/timeline', methods=['GET'])
def timeline():
    return render_template('samples/timeline.html')

@bp.route('/users', methods=['GET'])
def users():
    return render_template('samples/users.html')

@bp.route('/users-edit', methods=['GET'])
def users_edit():
    return render_template('samples/users-edit.html')

@bp.route('/users-view', methods=['GET'])
def users_view():
    return render_template('samples/users-view.html')

@bp.route('/widgets', methods=['GET'])
def widgets():
    return render_template('samples/widgets.html')

@bp.route('/widgets-apps', methods=['GET'])
def widgets_apps():
    return render_template('samples/widgets-apps.html')

@bp.route('/widgets-charts', methods=['GET'])
def widgets_charts():
    return render_template('samples/widgets-charts.html')

@bp.route('/widgets-banners', methods=['GET'])
def widgets_banners():
    return render_template('samples/widgets-banners.html')

@bp.route('/widgets-cards', methods=['GET'])
def widgets_cards():
    return render_template('samples/widgets-cards.html')

@bp.route('/widgets-data', methods=['GET'])
def widgets_data():
    return render_template('samples/widgets-data.html')

@bp.route('/error-coming-soon', methods=['GET'])
def error_coming_soon():
    return render_template('samples/error-coming-soon.html')
