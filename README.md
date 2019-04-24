# cert_regen

[![Build Status](https://travis-ci.org/ffalor/ffalor-cert_regen.svg?branch=master)](https://travis-ci.org/ffalor/ffalor-cert_regen)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/aae6b273b14f4c649d3db7135435bc56)](https://www.codacy.com/app/ffalor/ffalor-cert_regen?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=ffalor/ffalor-cert_regen&amp;utm_campaign=Badge_Grade)
![Puppet Forge downloads](https://img.shields.io/puppetforge/dt/ffalor/cert_regen.svg)
![GitHub issues](https://img.shields.io/github/issues/ffalor/ffalor-cert_regen.svg)
![Puppet Forge feedback score](https://img.shields.io/puppetforge/f/ffalor/cert_regen.svg?label=puppet%20score&style=plastic)
![Puppet Forge version](https://img.shields.io/puppetforge/v/ffalor/cert_regen.svg)
![Puppet Forge – PDK version](https://img.shields.io/puppetforge/pdk-version/ffalor/cert_regen.svg)

## Table of Contents

- [cert_regen](#certregen)
  - [Table of Contents](#table-of-contents)
  - [Description](#description)
  - [Usage](#usage)
    - [Paramaters](#paramaters)
    - [Puppet Task and Bolt](#puppet-task-and-bolt)
    - [Puppet Task API](#puppet-task-api)
  - [Development](#development)

## Description

This module includes a puppet task that can be used to regenerate node certificates.

This task will use `puppet config` to change the certname of the agent node.

A few reasons you may want to regenerate a certificate include:

>Note: this list is based on the assumption your certnames are derived from the DNS names of each node.

- Node's hostname changes
- Node's domain changes
- Certname was setup incorrectly

## Usage

### Paramaters

| Parameter | Description                                    | Default Value | Optional |
| --------- | ---------------------------------------------- | ------------- | -------- |
| certname  | New certname to use.                           | DNS Name      | True     |
| section   | Puppet.conf section to add the certname under. | main          | True     |

### Puppet Task and Bolt

To run an cert_regen task, use the task command, specifying the command to be executed.

- With PE on the command line, run `puppet task run cert_regen certname=<new_name> section=<main>`.
- With Bolt on the command line, run `bolt task run cert_regen certname=<new_name> section=<main>`.

### Puppet Task API

endpoint: `https://<puppet>:8143/orchestrator/v1/command/task`

method: `post`

body:

```json
{
  "environment": "production",
  "task": "cert_regen",
  "params": {
    "certname": "neptune.example.com",
    "section": "main"
  },
  "description": "Description for task",
  "scope": {
    "nodes": ["saturn.example.com"]
  }
}
```

You can also run tasks in the PE console. See PE task documentation for complete information.

## Development

Feel free to fork it fix my crappy code and create a PR (:
