{
  "widgets": [
    {
      "type": "metric",
      "x": 6,
      "y": 0,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [ { "expression": "SUM(SEARCH(' Namespace=\"ECS/ContainerInsights/Prometheus\" TaskDefinitionFamily=\"${task_def_family}\" MetricName=\"mqtt_proxy_publish_sent\"', 'Sum', 60))/60", "label": "Send rate, msg/sec", "id": "e1", "region": "${aws_region}" } ],
          [ { "expression": "SEARCH(' Namespace=\"ECS/ContainerInsights/Prometheus\" TaskDefinitionFamily=\"${task_def_family}\" MetricName=\"mqtt_proxy_publish_sent\"', 'Sum', 30)", "label": "Messages sent, by instance", "id": "e2", "region": "${aws_region}", "yAxis": "right" } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${aws_region}",
        "period": 30,
        "stat": "Average",
        "title": "MQTT Messages Sent",
        "yAxis": {
          "left": {
            "showUnits": false,
            "label": "msg/sec"
          },
          "right": {
            "label": "messages",
            "showUnits": false
          }
        }
      }
    },
    {
      "type": "metric",
      "x": 6,
      "y": 6,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [ { "expression": "SEARCH(' Namespace=\"ECS/ContainerInsights/Prometheus\" TaskDefinitionFamily=\"${task_def_family}\" MetricName=\"mqtt_proxy_clients_current\"', 'Average', 10)", "label": "MQTT Clients count", "id": "e1", "region": "${aws_region}" } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${aws_region}",
        "stat": "Average",
        "period": 30,
        "title": "MQTT Clients by node",
        "yAxis": {
          "left": {
            "showUnits": false,
            "label": "Clients number"
          }
        }
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 6,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [ { "expression": "SUM(SEARCH(' Namespace=\"ECS/ContainerInsights/Prometheus\" TaskDefinitionFamily=\"${task_def_family}\" MetricName=\"mqtt_proxy_clients_current\"', 'Average', 10))", "label": "Clients connected", "id": "e1", "region": "${aws_region}" } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${aws_region}",
        "stat": "Average",
        "period": 30,
        "title": "MQTT Clients Summary",
        "yAxis": {
          "left": {
            "showUnits": false,
            "label": "Clients number"
          }
        }
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [ { "expression": "SUM(SEARCH(' Namespace=\"ECS/ContainerInsights/Prometheus\" TaskDefinitionFamily=\"${task_def_family}\" MetricName=\"mqtt_proxy_publish_received\"', 'Sum', 60))/60", "label": "Received rate, msg/sec", "id": "e1", "region": "${aws_region}" } ],
          [ { "expression": "SUM(SEARCH(' Namespace=\"ECS/ContainerInsights/Prometheus\" TaskDefinitionFamily=\"${task_def_family}\" MetricName=\"mqtt_proxy_published_to_kafka\"', 'Sum', 60))/60", "label": "Kafka publish rate, msg/sec", "id": "e3", "region": "${aws_region}" } ],
          [ { "expression": "SEARCH(' Namespace=\"ECS/ContainerInsights/Prometheus\" TaskDefinitionFamily=\"${task_def_family}\" MetricName=\"mqtt_proxy_publish_received\"', 'Sum', 30)", "label": "Messages received, by instance", "id": "e2", "region": "${aws_region}", "yAxis": "right", "visible": false } ],
          [ { "expression": "SUM(SEARCH(' Namespace=\"ECS/ContainerInsights/Prometheus\" TaskDefinitionFamily=\"${task_def_family}\" MetricName=\"mqtt_proxy_publish_to_kafka_backlog\"', 'Average', 60))", "label": "Kafka publishing backlog", "id": "e4", "region": "${aws_region}", "yAxis": "right" } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${aws_region}",
        "period": 30,
        "stat": "Average",
        "title": "MQTT Messages Received",
        "yAxis": {
          "left": {
            "showUnits": false,
            "label": "msg/sec"
          },
          "right": {
            "showUnits": false,
            "label": "messages"
          }
        }
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 0,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          [ { "expression": "SEARCH(' Namespace=\"ECS/ContainerInsights/Prometheus\" TaskDefinitionFamily=\"${task_def_family}\" area=\"heap\" MetricName=\"jvm_memory_bytes_used\"', 'Average', 30)", "label": "Heap used, bytes", "id": "e1", "region": "${aws_region}" } ],
          [ { "expression": "SEARCH(' Namespace=\"ECS/ContainerInsights/Prometheus\" TaskDefinitionFamily=\"${task_def_family}\" area=\"heap\" MetricName=\"jvm_memory_bytes_max\"', 'Average', 30)", "label": "Heap limit, bytes", "id": "e2", "region": "${aws_region}" } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${aws_region}",
        "stat": "Average",
        "period": 300,
        "title": "Heap usage",
        "yAxis": {
          "left": {
            "showUnits": false,
            "label": "Memory, bytes"
          }
        }
      }
    }
  ]
}