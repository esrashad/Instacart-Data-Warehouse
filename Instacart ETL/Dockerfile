# Stage 1: Install system dependencies
FROM debian:buster as build

# Install necessary system dependencies
RUN apt-get update \
    && apt-get install -y gcc g++ unixodbc unixodbc-dev \
    && apt-get install -y curl gnupg2 build-essential freetds-dev libssl-dev \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql17 \
    && ACCEPT_EULA=Y apt-get install -y mssql-tools \
    && echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Stage 2: Build the final image
FROM apache/airflow:2.10.3

# Copy system dependencies from the build stage
COPY --from=build /usr/lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu
COPY --from=build /usr/local/bin /usr/local/bin
COPY --from=build /usr/local/lib /usr/local/lib
COPY --from=build /usr/local/include /usr/local/include

# Switch to airflow user
USER airflow

# Upgrade pip and install required Python packages
RUN pip install --upgrade pip
RUN pip install --no-cache-dir pyodbc apache-airflow-providers-microsoft-mssql pandas
