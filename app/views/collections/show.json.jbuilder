json.extract! @collection, :id, :status_with_icon, :status
json.busy @collection.busy?
json.task_available @collection.task_available?
json.has_annotations @collection.has_annotations?