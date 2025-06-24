FROM jupyter/datascience-notebook:latest

USER root

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    mysql-client \
    curl \
    vim \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Switch back to jovyan user
USER $NB_UID

# Install Python packages for SQL analysis
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Install Jupyter extensions for SQL
RUN jupyter labextension install @jupyterlab/sql-extension || true

# Configure Jupyter Lab
COPY jupyter_lab_config.py /home/jovyan/.jupyter/

# Create directory structure
RUN mkdir -p /home/jovyan/work/projects \
             /home/jovyan/work/exports \
             /home/jovyan/work/templates \
             /home/jovyan/notebooks/examples

# Copy starter notebooks
COPY notebooks/ /home/jovyan/notebooks/

# Set working directory
WORKDIR /home/jovyan

# Expose Jupyter port
EXPOSE 8888

# Start Jupyter Lab
CMD ["start-notebook.sh", "--ServerApp.token=''", "--ServerApp.password_required=False", "--ServerApp.disable_check_xsrf=True"]
