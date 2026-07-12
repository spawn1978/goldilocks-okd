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
  #oc patch deployment goldilocks-controller -n goldilocks --type='json' -p='[{"op": "remove", "path": "/spec/template/spec/securityContext/runAsUser"}]'
  #oc patch deployment goldilocks-dashboard -n goldilocks --type='json' -p='[{"op": "remove", "path": "/spec/template/spec/securityContext/runAsUser"}]'
  #oc patch deployment goldilocks-controller -n goldilocks --type='json' -p='[{"op": "remove", "path": "/spec/containers/0/securityContext/runAsUser"}]'
  #oc patch deployment goldilocks-dashboard -n goldilocks --type='json' -p='[{"op": "remove", "path": "/spec/containers/0/securityContext/runAsUser"}]'
  oc patch deployment goldilocks-dashboard -n goldilocks -p '{"spec":{"template":{"spec":{"containers":[{"name":"goldilocks","securityContext":{"runAsUser":null}}]}}}}'
  oc patch deployment goldilocks-controller -n goldilocks -p '{"spec":{"template":{"spec":{"containers":[{"name":"goldilocks","securityContext":{"runAsUser":null}}]}}}}'

  # Create route
  oc apply -f route-goldilocks.yaml

  #Goldilocks solo crea objetos VPA en namespaces con el label correcto:
  # Etiquetar cada namespace que querés monitorear                                                                                                                                                                                                         
  #oc label namespace demo-python goldilocks.fairwinds.com/enabled=true                                                                                                                                                                                       
  #Verificar que Goldilocks creó los VPA objects:                                                                                                                                                                                                             
  #oc get vpa -n demo-python
  #oc get vpa -n demo-nodejs                                                                                                                                                                                                                                  

  #Solución 3: Verificar RBAC de Goldilocks en OpenShift                                                                                                                                                                                                      
  #                                                                                                                                                                                                                                                         
  #OpenShift puede bloquear permisos por SCCs. Verificar:
                                                                                                                                                                                                                                                             
  # Ver si el controller de Goldilocks tiene errores
  sleep 15
  oc logs -n goldilocks deployment/goldilocks-controller -f                                                                                                                                                                                                  
                                                                                                                                                                                                                                                           
  # Ver si el dashboard tiene errores leyendo VPAs                                                                                                                                                                                                           
  #oc logs -n goldilocks deployment/goldilocks-dashboard -f                                                                                                                                                                                                 
                                                                                                                                                                                                                                                             
  #Si ves errores de permisos, agregar ClusterRole:                                                                                                                                                                                                         
  #oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:goldilocks:goldilocks
