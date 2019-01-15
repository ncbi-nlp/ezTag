# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20190115151818) do

  create_table "collections", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.integer  "user_id"
    t.string   "name"
    t.integer  "documents_count",                default: 0, null: false
    t.string   "note"
    t.string   "source"
    t.string   "cdate"
    t.string   "key"
    t.string   "xml_url",           limit: 1000
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.integer  "annotations_count",              default: 0
    t.index ["key"], name: "index_collections_on_key", using: :btree
    t.index ["user_id"], name: "index_collections_on_user_id", using: :btree
  end

  create_table "documents", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.integer  "collection_id"
    t.string   "did"
    t.datetime "user_updated_at"
    t.datetime "tool_updated_at"
    t.integer  "annotations_count",                    default: 0,     null: false
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
    t.text     "xml",               limit: 4294967295
    t.text     "title",             limit: 65535
    t.string   "key"
    t.integer  "did_no"
    t.integer  "batch_id",                             default: 0
    t.integer  "batch_no",                             default: 0
    t.boolean  "done",                                 default: false
    t.boolean  "curatable",                            default: true
    t.index ["collection_id"], name: "index_documents_on_collection_id", using: :btree
    t.index ["did"], name: "index_documents_on_did", using: :btree
  end

  create_table "entity_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.integer  "collection_id"
    t.string   "name"
    t.string   "color"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["collection_id"], name: "index_entity_types_on_collection_id", using: :btree
  end

  create_table "lexicon_groups", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.string   "name"
    t.integer  "user_id"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.integer  "lexicons_count",             default: 0
    t.string   "key",            limit: 100
    t.index ["key"], name: "index_lexicon_groups_on_key", using: :btree
    t.index ["user_id"], name: "index_lexicon_groups_on_user_id", using: :btree
  end

  create_table "lexicons", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.string   "ltype"
    t.string   "lexicon_id"
    t.text     "name",             limit: 65535
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.integer  "lexicon_group_id"
    t.index ["lexicon_group_id"], name: "index_lexicons_on_lexicon_group_id", using: :btree
    t.index ["lexicon_id"], name: "index_lexicons_on_lexicon_id", using: :btree
  end

  create_table "models", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.string   "url"
    t.integer  "user_id"
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_models_on_user_id", using: :btree
  end

  create_table "tasks", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.integer  "user_id"
    t.integer  "collection_id"
    t.string   "tagger"
    t.integer  "task_type"
    t.string   "pre_trained_model"
    t.string   "status"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.datetime "tool_begin_at"
    t.datetime "tool_end_at"
    t.datetime "canceled_at"
    t.integer  "model_id"
    t.integer  "lexicon_group_id"
    t.boolean  "has_model",         default: false
    t.boolean  "has_lexicon_group", default: false
    t.index ["collection_id"], name: "index_tasks_on_collection_id", using: :btree
    t.index ["lexicon_group_id"], name: "index_tasks_on_lexicon_group_id", using: :btree
    t.index ["model_id"], name: "index_tasks_on_model_id", using: :btree
    t.index ["user_id"], name: "index_tasks_on_user_id", using: :btree
  end

  create_table "upload_batches", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.string   "session_str"
    t.string   "ip"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.string   "email"
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.boolean  "super_admin",            default: false
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["ip"], name: "index_users_on_ip", using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
    t.index ["session_str"], name: "index_users_on_session_str", using: :btree
  end

  add_foreign_key "collections", "users"
  add_foreign_key "documents", "collections"
  add_foreign_key "entity_types", "collections"
  add_foreign_key "lexicon_groups", "users"
  add_foreign_key "lexicons", "lexicon_groups"
  add_foreign_key "models", "users"
  add_foreign_key "tasks", "collections"
  add_foreign_key "tasks", "lexicon_groups"
  add_foreign_key "tasks", "models"
  add_foreign_key "tasks", "users"
end
