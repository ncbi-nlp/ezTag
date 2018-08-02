status = @collection.status

json.extract! @collection, :id
json.status_with_icon @collection.status_with_icon(status)
json.status status
json.busy @collection.busy?(status)
json.task_available @collection.task_available?(status)
json.has_annotations @collection.has_annotations?