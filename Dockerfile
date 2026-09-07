FROM ghcr.io/openclaw/openclaw:2026.8.2
USER root
COPY entrypoint.sh /entrypoint.sh
COPY monday_report.sh /opt/monday_report.sh
COPY monday_format.mjs /opt/monday_format.mjs
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
