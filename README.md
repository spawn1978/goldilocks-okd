
## Acceder al dashboard

```bash
# Obtener la URL de la route generada por el script
oc get route goldilocks-dashboard -n goldilocks

# O hacer port-forward si no se creo la route
oc port-forward svc/goldilocks-dashboard 8080:80 -n goldilocks
# Abrir http://localhost:8080
```

---

## Prueba sobre OpenShift CRC 4.20

El siguiente flujo fue testeado sobre **OpenShift Local (CRC) v4.20** con usuario `kubeadmin`.



```bash
# Loguearse al cluster con un usuario con los permisos necesarios

# Clonar el repositorio de comunitario de autoscaler
cd /tmp & git clone https://github.com/kubernetes/autoscaler.git
cd /tmp/autoscaler/vertical-pod-autoscaler/hack
./vpa-up.sh

oc new-project goldilocks --display-name="goldilocks" --description="Goldilocks Project description"

helm repo list
helm repo add fairwinds-stable https://charts.fairwinds.com/stable
helm repo list
helm install goldilocks --namespace goldilocks --set  installVPA=true fairwinds-stable/goldilocks

#Agrego SA
oc adm policy add-scc-to-user anyuid -z goldilocks-dashboard -n goldilocks

#Si falla, darle permisos
oc adm policy add-scc-to-user anyuid -z goldilocks-controller -n goldilocks

oc apply -f clusterrole-goldilock-dashboard.yaml
oc apply -f clusterrole-goldilock-controller.yaml

# Patch deployment, elimina runUserAs
  
oc patch deployment goldilocks-dashboard -n goldilocks -p '{"spec":{"template":{"spec":{"containers":[{"name":"goldilocks","securityContext":{"runAsUser":null}}]}}}}'
oc patch deployment goldilocks-controller -n goldilocks -p '{"spec":{"template":{"spec":{"containers":[{"name":"goldilocks","securityContext":{"runAsUser":null}}]}}}}'

# Create route
oc apply -f route-goldilocks.yaml

# Verificar que Goldilocks este corriendo
oc get pods -n goldilocks

# Verificar que se crearon los VPAs en el namespace de prueba
oc get vpa -n demo-java-rightsizing

# Ver recomendaciones crudas de un VPA
oc describe vpa java-rightsizing-test -n demo-java-rightsizing

# Acceder al dashboard (ver seccion anterior)
oc get route goldilocks-dashboard -n goldilocks
```

Salida esperada del `describe vpa`:

```
Recommendation:
  Container Recommendations:
    Container Name: java-rightsizing-test
      Lower Bound:
        Cpu:     12m
        Memory:  262144k
      Target:
        Cpu:     25m
        Memory:  300Mi
      Upper Bound:
        Cpu:     150m
        Memory:  512Mi
```

> El dashboard mostrara que los requests actuales (`2000m` CPU / `2Gi` RAM) estan muy por encima del **Target** recomendado, evidenciando el sobredimensionamiento.

---

## Desinstalar

```bash
helm uninstall goldilocks -n goldilocks
oc delete namespace goldilocks
```

Para remover tambien el VPA Operator instalado por el script, referirse a la documentacion del operador segun el metodo de instalacion utilizado.

---

## Referencias

- [Goldilocks — GitHub (FairwindsOps)](https://github.com/FairwindsOps/goldilocks)
- [Introduccion oficial de Fairwinds](https://www.fairwinds.com/blog/introducing-goldilocks-a-tool-for-recommending-resource-requests)
- [Documentacion avanzada — flags y labels](https://goldilocks.docs.fairwinds.com/advanced/)
- [Helm chart en Artifact Hub](https://artifacthub.io/packages/helm/fairwinds-stable/goldilocks)
- [Right-sizing con Goldilocks — AWS Open Source Blog](https://aws.amazon.com/blogs/opensource/right-size-your-kubernetes-applications-using-open-source-goldilocks-for-cost-optimization/)
