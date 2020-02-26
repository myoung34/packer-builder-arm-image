apt-get update
apt-get install -y python3 python3-pip bluez libbluetooth-dev apt-transport-https unzip
pip3 install tilty
wget -qO- https://repos.influxdata.com/influxdb.key | apt-key add -
echo "deb https://repos.influxdata.com/debian buster stable" | tee /etc/apt/sources.list.d/influxdb.list
apt-get update
apt-get install -y influxdb
systemctl unmask influxdb
systemctl enable influxdb
systemctl start influxdb
apt-get install -y libfontconfig1
apt-get -f -y install
wget https://dl.grafana.com/oss/release/grafana-rpi_6.6.1_armhf.deb
dpkg -i grafana-rpi_6.6.1_armhf.deb
rm *.deb
systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server
wget https://releases.hashicorp.com/terraform/0.12.21/terraform_0.12.21_linux_arm.zip
unzip terraform_0.12.21_linux_arm.zip
mv terraform /usr/bin && chmod +x /usr/bin/terraform

# grafana plugin
wget https://releases.hashicorp.com/terraform-provider-grafana/1.5.0/terraform-provider-grafana_1.5.0_linux_arm.zip
unzip terraform-provider-grafana_1.5.0_linux_arm.zip
mv terraform-provider-grafana_v1.5.0_x4 /usr/local/bin && chmod +x /usr/local/bin/terraform-provider-grafana_v1.5.0_x4

wget https://releases.hashicorp.com/terraform-provider-influxdb/1.3.0/terraform-provider-influxdb_1.3.0_linux_arm.zip
unzip terraform-provider-influxdb_1.3.0_linux_arm.zip
mv terraform-provider-influxdb_v1.3.0_x4 /usr/local/bin && chmod +x /usr/local/bin/terraform-provider-influxdb_v1.3.0_x4
rm *.zip

cd /tmp
cat <<EOF >influx.tf
provider "influxdb" {
  version = "1.3.0"
}

resource "influxdb_database" "tilty" {
  name = "tilty"
}
EOF

terraform init
terraform apply -auto-approve
rm influx.tf

cat <<EOF >grafana-dashboard.json
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": "-- Grafana --",
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "gnetId": null,
  "graphTooltip": 0,
  "id": 1,
  "links": [],
  "panels": [
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": null,
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 20,
        "w": 24,
        "x": 0,
        "y": 0
      },
      "hideTimeOverride": false,
      "id": 2,
      "interval": "",
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "nullPointMode": "null",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "groupBy": [
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "measurement": "temperature",
          "orderByTime": "ASC",
          "policy": "autogen",
          "query": "SELECT \"value\" FROM \"autogen\".\"temperature\" ",
          "rawQuery": true,
          "refId": "A",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              }
            ]
          ],
          "tags": []
        },
        {
          "groupBy": [
            {
              "params": [
                "\$__interval"
              ],
              "type": "time"
            },
            {
              "params": [
                "null"
              ],
              "type": "fill"
            }
          ],
          "orderByTime": "ASC",
          "policy": "default",
          "query": "SELECT \"value\" FROM \"autogen\".\"gravity\" ",
          "rawQuery": true,
          "refId": "B",
          "resultFormat": "time_series",
          "select": [
            [
              {
                "params": [
                  "value"
                ],
                "type": "field"
              },
              {
                "params": [],
                "type": "mean"
              }
            ]
          ],
          "tags": []
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Panel Title",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    }
  ],
  "refresh": false,
  "schemaVersion": 20,
  "style": "dark",
  "tags": [],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-1h",
    "to": "now"
  },
  "timepicker": {
    "refresh_intervals": [
      "5s",
      "10s",
      "30s",
      "1m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "1d"
    ]
  },
  "timezone": "utc",
  "title": "Tilty",
  "uid": "ccMnliwZk",
  "version": 15
}
EOF

cat <<EOF >grafana.tf
provider "grafana" {
  version = "1.5.0"
}

resource "grafana_dashboard" "metrics" {
  config_json = file("grafana-dashboard.json")
}

resource "grafana_data_source" "influxdb" {
  type          = "influxdb"
  name          = "tilty"
  database_name = "tilty"
}
EOF
terraform init
terraform apply -auto-approve
rm grafana.tf
