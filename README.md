# sc-webhooks
A webhook API built on top of various Microsoft System Center products.

This is work in progress!

Will eventually be:

- Web interface (should be internet facing)
- Web API (could be internet facing)
 - Create outgoing webhook based on a given event
 - Create ingoing webhook

The idea is to be able to use webhooks to integrate other services with System Center. Webhooks is a really easy and simple, yet highly effective, way to integrate different services.

An example of an outgoing webhook
- New incident request in Service Manager
- New alert in Operations Manager

An example of an ingoing webhook
- Create new incident request based on the webhook payload

