
# Template configs

You can add this templates under `filebeat.autodiscover.providers.templates`. Just add this templates to you `sak-ekf` module config and add needed label with value on pod/deployment (kubernetes.labels.logtype). Most of templates are multiline. [More info](https://www.elastic.co/guide/en/beats/filebeat/current/multiline-examples.html)

## Nginx
```
{
  "condition.equals" = {
    "kubernetes.labels.logtype" = "nginx"
  },
  "config" = [
    {
      "module" = "nginx",
      "access" = {
        "enabled" = true,
        "var.paths" = [
          "/var/log/nginx/access.log*"
        ]
      },
      "error" = {
        "enabled" = true,
        "var.paths" = [
          "/var/log/nginx/error.log*"
        ]
      }
    }
  ]
}
```

## Kafka
```
{
  "condition.equals" = {
    "kubernetes.labels.logtype" = "kafka"
  },
  "config" = [
    {
      "module" = "kafka",
      "logs" = {
        "enabled" = true,
        "var.paths" = [
          "/var/log/kafka/*.log*"
        ]
      }
    }
  ]
}
```

## Java
```
{
  "condition.equals" = {
    "kubernetes.labels.logtype" = "java"
  },
  "config" = [
    {
      "type" = "container",
      "paths" = [
        "/var/log/containers/*-$${data.kubernetes.container.id}.log"
      ],
      "exclude_lines" = [
        "^\\s+[\\-`('.|_]"
      ],
      "multiline.type"    = "pattern",
      "multiline.pattern" = "^[[:space:]]",
      "multiline.negate"  = false,
      "multiline.match"   = "after"
    }
  ]

}
```        

## Multiline logs with timestamp  
```
{
  "condition.equals" = {
    "kubernetes.labels.logtype" = "multiline_timestamp"
  },
  "config" = [
    {
      "type" = "container",
      "paths" = [
        "/var/log/containers/*-$${data.kubernetes.container.id}.log"
      ],
      "exclude_lines" = [
        "^\\s+[\\-`('.|_]"
      ],
      "multiline.pattern" = "^\\[[0-9]{4}-[0-9]{2}-[0-9]{2}"
      "multiline.negate"  = "true"
      "multiline.match"   = "after"
    }
  ]
}
```    

## Warning logs
```
{
  "condition.equals" = {
    "kubernetes.labels.logtype" = "warning"
  },
  "config" = [
    {
      "type" = "container",
      "paths" = [
        "/var/log/containers/*-$${data.kubernetes.container.id}.log"
      ],
      "exclude_lines" = [
        "^\\s+[\\-`('.|_]"
      ],
      "multiline.pattern" = "^WARN"
      "multiline.negate"  = "true"
      "multiline.match"   = "after"
    }
  ]
}
```

## Error logs
```
{
  "condition.equals" = {
    "kubernetes.labels.logtype" = "error"
  },
  "config" = [
    {
      "type" = "container",
      "paths" = [
        "/var/log/containers/*-$${data.kubernetes.container.id}.log"
      ],
      "exclude_lines" = [
        "^\\s+[\\-`('.|_]"
      ],
      "multiline.pattern" = "^ERR"
      "multiline.negate"  = "true"
      "multiline.match"   = "after"
    }
  ]
}
```

## Debug logs

```
{
  "condition.equals" = {
    "kubernetes.labels.logtype" = "debug"
  },
  "config" = [
    {
      "type" = "container",
      "paths" = [
        "/var/log/containers/*-$${data.kubernetes.container.id}.log"
      ],
      "exclude_lines" = [
        "^\\s+[\\-`('.|_]"
      ],
      "multiline.pattern" = "(?>DEBUG|DBG)"
      "multiline.negate"  = "true"
      "multiline.match"   = "after"
    }
  ]
}
```
