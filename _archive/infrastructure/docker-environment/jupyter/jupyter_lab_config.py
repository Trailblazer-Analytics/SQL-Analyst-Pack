"""
Jupyter Lab configuration for SQL Analyst Pack
Optimized for data analysis workflows
"""

c = get_config()

# Server configuration
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.open_browser = False
c.ServerApp.allow_root = True
c.ServerApp.notebook_dir = '/home/jovyan'

# Security settings (development only!)
c.ServerApp.token = ''
c.ServerApp.password = ''
c.ServerApp.disable_check_xsrf = True
c.ServerApp.allow_origin = '*'
c.ServerApp.allow_credentials = True

# Lab settings
c.LabApp.default_url = '/lab'

# File management
c.ContentsManager.allow_hidden = True
c.FileContentsManager.delete_to_trash = False

# Kernel settings
c.MappingKernelManager.default_kernel_name = 'python3'

# Session settings
c.MappingKernelManager.cull_idle_timeout = 3600  # 1 hour
c.MappingKernelManager.cull_interval = 300  # 5 minutes

# Extensions
c.LabApp.collaborative = False

# Custom CSS and themes
c.LabApp.user_settings_dir = '/home/jovyan/.jupyter/lab/user-settings'

# Logging
c.Application.log_level = 'INFO'
