export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.18"
  }
  public: {
    Tables: {
      agent_approvals: {
        Row: {
          action_type: string
          case_id: string
          created_at: string
          decided_at: string | null
          expires_at: string
          id: string
          owner_user_id: string
          payload: Json
          payload_hash: string
          status: string
        }
        Insert: {
          action_type: string
          case_id: string
          created_at?: string
          decided_at?: string | null
          expires_at?: string
          id?: string
          owner_user_id: string
          payload?: Json
          payload_hash: string
          status?: string
        }
        Update: {
          action_type?: string
          case_id?: string
          created_at?: string
          decided_at?: string | null
          expires_at?: string
          id?: string
          owner_user_id?: string
          payload?: Json
          payload_hash?: string
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "agent_approvals_case_id_fkey"
            columns: ["case_id"]
            isOneToOne: false
            referencedRelation: "agent_cases"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "agent_approvals_owner_user_id_fkey"
            columns: ["owner_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      agent_case_steps: {
        Row: {
          attempt: number
          case_id: string
          completed_at: string | null
          created_at: string
          error_code: string | null
          error_message: string | null
          id: string
          input_payload: Json
          output_payload: Json
          started_at: string | null
          status: string
          step_key: string
        }
        Insert: {
          attempt?: number
          case_id: string
          completed_at?: string | null
          created_at?: string
          error_code?: string | null
          error_message?: string | null
          id?: string
          input_payload?: Json
          output_payload?: Json
          started_at?: string | null
          status?: string
          step_key: string
        }
        Update: {
          attempt?: number
          case_id?: string
          completed_at?: string | null
          created_at?: string
          error_code?: string | null
          error_message?: string | null
          id?: string
          input_payload?: Json
          output_payload?: Json
          started_at?: string | null
          status?: string
          step_key?: string
        }
        Relationships: [
          {
            foreignKeyName: "agent_case_steps_case_id_fkey"
            columns: ["case_id"]
            isOneToOne: false
            referencedRelation: "agent_cases"
            referencedColumns: ["id"]
          },
        ]
      }
      agent_cases: {
        Row: {
          artisan_profile_id: string | null
          case_type: string
          context: Json
          created_at: string
          current_step: string | null
          id: string
          idempotency_key: string | null
          input_payload: Json
          last_error_code: string | null
          next_retry_at: string | null
          owner_user_id: string
          product_id: string | null
          retry_count: number
          status: string
          updated_at: string
        }
        Insert: {
          artisan_profile_id?: string | null
          case_type: string
          context?: Json
          created_at?: string
          current_step?: string | null
          id?: string
          idempotency_key?: string | null
          input_payload?: Json
          last_error_code?: string | null
          next_retry_at?: string | null
          owner_user_id: string
          product_id?: string | null
          retry_count?: number
          status?: string
          updated_at?: string
        }
        Update: {
          artisan_profile_id?: string | null
          case_type?: string
          context?: Json
          created_at?: string
          current_step?: string | null
          id?: string
          idempotency_key?: string | null
          input_payload?: Json
          last_error_code?: string | null
          next_retry_at?: string | null
          owner_user_id?: string
          product_id?: string | null
          retry_count?: number
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "agent_cases_artisan_profile_id_fkey"
            columns: ["artisan_profile_id"]
            isOneToOne: false
            referencedRelation: "artisan_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "agent_cases_owner_user_id_fkey"
            columns: ["owner_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "agent_cases_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      artisan_profiles: {
        Row: {
          bio: string | null
          country: string
          craft_region: string | null
          craft_traditions: string[]
          created_at: string
          id: string
          is_public: boolean
          languages: string[]
          onboarding_status: string
          public_name: string
          public_slug: string | null
          state: string | null
          updated_at: string
          user_id: string
          verification_status: string
          years_of_experience: number | null
        }
        Insert: {
          bio?: string | null
          country?: string
          craft_region?: string | null
          craft_traditions?: string[]
          created_at?: string
          id?: string
          is_public?: boolean
          languages?: string[]
          onboarding_status?: string
          public_name: string
          public_slug?: string | null
          state?: string | null
          updated_at?: string
          user_id: string
          verification_status?: string
          years_of_experience?: number | null
        }
        Update: {
          bio?: string | null
          country?: string
          craft_region?: string | null
          craft_traditions?: string[]
          created_at?: string
          id?: string
          is_public?: boolean
          languages?: string[]
          onboarding_status?: string
          public_name?: string
          public_slug?: string | null
          state?: string | null
          updated_at?: string
          user_id?: string
          verification_status?: string
          years_of_experience?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "artisan_profiles_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      buyer_matches: {
        Row: {
          buyer_request_id: string
          created_at: string
          id: string
          match_reasons: Json
          match_score: number
          product_id: string
          status: string
        }
        Insert: {
          buyer_request_id: string
          created_at?: string
          id?: string
          match_reasons?: Json
          match_score: number
          product_id: string
          status?: string
        }
        Update: {
          buyer_request_id?: string
          created_at?: string
          id?: string
          match_reasons?: Json
          match_score?: number
          product_id?: string
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "buyer_matches_buyer_request_id_fkey"
            columns: ["buyer_request_id"]
            isOneToOne: false
            referencedRelation: "buyer_requests"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "buyer_matches_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      buyer_profiles: {
        Row: {
          buyer_type: string
          created_at: string
          organization_name: string | null
          preferred_categories: string[]
          preferred_regions: string[]
          updated_at: string
          user_id: string
        }
        Insert: {
          buyer_type?: string
          created_at?: string
          organization_name?: string | null
          preferred_categories?: string[]
          preferred_regions?: string[]
          updated_at?: string
          user_id: string
        }
        Update: {
          buyer_type?: string
          created_at?: string
          organization_name?: string | null
          preferred_categories?: string[]
          preferred_regions?: string[]
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "buyer_profiles_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      buyer_requests: {
        Row: {
          budget_max: number | null
          budget_min: number | null
          buyer_user_id: string
          category_id: string | null
          created_at: string
          currency: string
          delivery_region: string | null
          description: string | null
          id: string
          needed_by: string | null
          quantity: number
          status: string
          title: string
          updated_at: string
          visibility: string
        }
        Insert: {
          budget_max?: number | null
          budget_min?: number | null
          buyer_user_id: string
          category_id?: string | null
          created_at?: string
          currency?: string
          delivery_region?: string | null
          description?: string | null
          id?: string
          needed_by?: string | null
          quantity?: number
          status?: string
          title: string
          updated_at?: string
          visibility?: string
        }
        Update: {
          budget_max?: number | null
          budget_min?: number | null
          buyer_user_id?: string
          category_id?: string | null
          created_at?: string
          currency?: string
          delivery_region?: string | null
          description?: string | null
          id?: string
          needed_by?: string | null
          quantity?: number
          status?: string
          title?: string
          updated_at?: string
          visibility?: string
        }
        Relationships: [
          {
            foreignKeyName: "buyer_requests_buyer_user_id_fkey"
            columns: ["buyer_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "buyer_requests_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "craft_categories"
            referencedColumns: ["id"]
          },
        ]
      }
      cart_items: {
        Row: {
          cart_id: string
          created_at: string
          id: string
          product_id: string
          quantity: number
          updated_at: string
        }
        Insert: {
          cart_id: string
          created_at?: string
          id?: string
          product_id: string
          quantity?: number
          updated_at?: string
        }
        Update: {
          cart_id?: string
          created_at?: string
          id?: string
          product_id?: string
          quantity?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "cart_items_cart_id_fkey"
            columns: ["cart_id"]
            isOneToOne: false
            referencedRelation: "carts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cart_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      carts: {
        Row: {
          buyer_user_id: string
          created_at: string
          currency: string
          id: string
          updated_at: string
        }
        Insert: {
          buyer_user_id: string
          created_at?: string
          currency?: string
          id?: string
          updated_at?: string
        }
        Update: {
          buyer_user_id?: string
          created_at?: string
          currency?: string
          id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "carts_buyer_user_id_fkey"
            columns: ["buyer_user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      craft_categories: {
        Row: {
          created_at: string
          description: string | null
          id: string
          is_active: boolean
          name: string
          parent_id: string | null
          slug: string
          sort_order: number
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name: string
          parent_id?: string | null
          slug: string
          sort_order?: number
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          is_active?: boolean
          name?: string
          parent_id?: string | null
          slug?: string
          sort_order?: number
        }
        Relationships: [
          {
            foreignKeyName: "craft_categories_parent_id_fkey"
            columns: ["parent_id"]
            isOneToOne: false
            referencedRelation: "craft_categories"
            referencedColumns: ["id"]
          },
        ]
      }
      market_price_observations: {
        Row: {
          category_id: string | null
          craft_terms: string[]
          created_at: string
          currency: string
          evidence: Json
          id: string
          is_verified: boolean
          item_condition: string | null
          observed_at: string
          price_max: number
          price_min: number
          region: string | null
          source_name: string
          source_url: string | null
          unit: string
        }
        Insert: {
          category_id?: string | null
          craft_terms?: string[]
          created_at?: string
          currency?: string
          evidence?: Json
          id?: string
          is_verified?: boolean
          item_condition?: string | null
          observed_at: string
          price_max: number
          price_min: number
          region?: string | null
          source_name: string
          source_url?: string | null
          unit?: string
        }
        Update: {
          category_id?: string | null
          craft_terms?: string[]
          created_at?: string
          currency?: string
          evidence?: Json
          id?: string
          is_verified?: boolean
          item_condition?: string | null
          observed_at?: string
          price_max?: number
          price_min?: number
          region?: string | null
          source_name?: string
          source_url?: string | null
          unit?: string
        }
        Relationships: [
          {
            foreignKeyName: "market_price_observations_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "craft_categories"
            referencedColumns: ["id"]
          },
        ]
      }
      negotiation_messages: {
        Row: {
          body: string
          created_at: string
          currency: string
          id: string
          message_type: string
          offer_amount: number | null
          sender_user_id: string
          thread_id: string
        }
        Insert: {
          body: string
          created_at?: string
          currency?: string
          id?: string
          message_type?: string
          offer_amount?: number | null
          sender_user_id: string
          thread_id: string
        }
        Update: {
          body?: string
          created_at?: string
          currency?: string
          id?: string
          message_type?: string
          offer_amount?: number | null
          sender_user_id?: string
          thread_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "negotiation_messages_sender_user_id_fkey"
            columns: ["sender_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "negotiation_messages_thread_id_fkey"
            columns: ["thread_id"]
            isOneToOne: false
            referencedRelation: "negotiation_threads"
            referencedColumns: ["id"]
          },
        ]
      }
      negotiation_threads: {
        Row: {
          artisan_user_id: string
          buyer_request_id: string | null
          buyer_user_id: string
          created_at: string
          id: string
          product_id: string
          quantity: number
          status: string
          updated_at: string
        }
        Insert: {
          artisan_user_id: string
          buyer_request_id?: string | null
          buyer_user_id: string
          created_at?: string
          id?: string
          product_id: string
          quantity?: number
          status?: string
          updated_at?: string
        }
        Update: {
          artisan_user_id?: string
          buyer_request_id?: string | null
          buyer_user_id?: string
          created_at?: string
          id?: string
          product_id?: string
          quantity?: number
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "negotiation_threads_artisan_user_id_fkey"
            columns: ["artisan_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "negotiation_threads_buyer_request_id_fkey"
            columns: ["buyer_request_id"]
            isOneToOne: false
            referencedRelation: "buyer_requests"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "negotiation_threads_buyer_user_id_fkey"
            columns: ["buyer_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "negotiation_threads_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      order_events: {
        Row: {
          actor_user_id: string | null
          created_at: string
          details: Json
          event_type: string
          id: string
          order_id: string
        }
        Insert: {
          actor_user_id?: string | null
          created_at?: string
          details?: Json
          event_type: string
          id?: string
          order_id: string
        }
        Update: {
          actor_user_id?: string | null
          created_at?: string
          details?: Json
          event_type?: string
          id?: string
          order_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "order_events_actor_user_id_fkey"
            columns: ["actor_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_events_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      order_items: {
        Row: {
          created_at: string
          id: string
          line_total: number
          order_id: string
          product_id: string | null
          product_title_snapshot: string
          quantity: number
          unit_price: number
        }
        Insert: {
          created_at?: string
          id?: string
          line_total: number
          order_id: string
          product_id?: string | null
          product_title_snapshot: string
          quantity: number
          unit_price: number
        }
        Update: {
          created_at?: string
          id?: string
          line_total?: number
          order_id?: string
          product_id?: string | null
          product_title_snapshot?: string
          quantity?: number
          unit_price?: number
        }
        Relationships: [
          {
            foreignKeyName: "order_items_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      orders: {
        Row: {
          artisan_user_id: string
          buyer_user_id: string
          confirmed_at: string | null
          created_at: string
          currency: string
          id: string
          idempotency_key: string | null
          negotiation_thread_id: string | null
          order_number: string
          shipping_address_snapshot: Json | null
          shipping_amount: number
          status: string
          subtotal: number
          tax_amount: number
          total_amount: number
          updated_at: string
        }
        Insert: {
          artisan_user_id: string
          buyer_user_id: string
          confirmed_at?: string | null
          created_at?: string
          currency?: string
          id?: string
          idempotency_key?: string | null
          negotiation_thread_id?: string | null
          order_number: string
          shipping_address_snapshot?: Json | null
          shipping_amount?: number
          status?: string
          subtotal?: number
          tax_amount?: number
          total_amount?: number
          updated_at?: string
        }
        Update: {
          artisan_user_id?: string
          buyer_user_id?: string
          confirmed_at?: string | null
          created_at?: string
          currency?: string
          id?: string
          idempotency_key?: string | null
          negotiation_thread_id?: string | null
          order_number?: string
          shipping_address_snapshot?: Json | null
          shipping_amount?: number
          status?: string
          subtotal?: number
          tax_amount?: number
          total_amount?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "orders_artisan_user_id_fkey"
            columns: ["artisan_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_buyer_user_id_fkey"
            columns: ["buyer_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_negotiation_thread_id_fkey"
            columns: ["negotiation_thread_id"]
            isOneToOne: false
            referencedRelation: "negotiation_threads"
            referencedColumns: ["id"]
          },
        ]
      }
      product_media: {
        Row: {
          alt_text: string | null
          created_at: string
          id: string
          is_primary: boolean
          media_type: string
          product_id: string
          sort_order: number
          storage_bucket: string
          storage_path: string
        }
        Insert: {
          alt_text?: string | null
          created_at?: string
          id?: string
          is_primary?: boolean
          media_type?: string
          product_id: string
          sort_order?: number
          storage_bucket?: string
          storage_path: string
        }
        Update: {
          alt_text?: string | null
          created_at?: string
          id?: string
          is_primary?: boolean
          media_type?: string
          product_id?: string
          sort_order?: number
          storage_bucket?: string
          storage_path?: string
        }
        Relationships: [
          {
            foreignKeyName: "product_media_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      product_price_guidance: {
        Row: {
          agent_case_id: string | null
          artisan_user_id: string
          comparable_count: number
          confidence: string
          currency: string
          explanation: string | null
          generated_at: string
          id: string
          indicative_max: number | null
          indicative_min: number | null
          product_id: string
          source_observation_ids: string[]
          unit: string
        }
        Insert: {
          agent_case_id?: string | null
          artisan_user_id: string
          comparable_count?: number
          confidence?: string
          currency?: string
          explanation?: string | null
          generated_at?: string
          id?: string
          indicative_max?: number | null
          indicative_min?: number | null
          product_id: string
          source_observation_ids?: string[]
          unit?: string
        }
        Update: {
          agent_case_id?: string | null
          artisan_user_id?: string
          comparable_count?: number
          confidence?: string
          currency?: string
          explanation?: string | null
          generated_at?: string
          id?: string
          indicative_max?: number | null
          indicative_min?: number | null
          product_id?: string
          source_observation_ids?: string[]
          unit?: string
        }
        Relationships: [
          {
            foreignKeyName: "product_price_guidance_agent_case_id_fkey"
            columns: ["agent_case_id"]
            isOneToOne: false
            referencedRelation: "agent_cases"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_price_guidance_artisan_user_id_fkey"
            columns: ["artisan_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_price_guidance_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      product_private_terms: {
        Row: {
          artisan_user_id: string
          floor_price: number
          notes: string | null
          product_id: string
          updated_at: string
        }
        Insert: {
          artisan_user_id: string
          floor_price: number
          notes?: string | null
          product_id: string
          updated_at?: string
        }
        Update: {
          artisan_user_id?: string
          floor_price?: number
          notes?: string | null
          product_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "product_private_terms_artisan_user_id_fkey"
            columns: ["artisan_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_private_terms_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: true
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      products: {
        Row: {
          ai_generated_fields: Json
          artisan_profile_id: string
          available_quantity: number
          category_id: string | null
          craft_origin: string | null
          craft_story: string | null
          created_at: string
          currency: string
          description: string | null
          id: string
          is_handmade: boolean
          materials: string[]
          min_order_quantity: number
          price: number
          published_at: string | null
          short_description: string | null
          slug: string
          status: string
          techniques: string[]
          title: string
          updated_at: string
        }
        Insert: {
          ai_generated_fields?: Json
          artisan_profile_id: string
          available_quantity?: number
          category_id?: string | null
          craft_origin?: string | null
          craft_story?: string | null
          created_at?: string
          currency?: string
          description?: string | null
          id?: string
          is_handmade?: boolean
          materials?: string[]
          min_order_quantity?: number
          price: number
          published_at?: string | null
          short_description?: string | null
          slug: string
          status?: string
          techniques?: string[]
          title: string
          updated_at?: string
        }
        Update: {
          ai_generated_fields?: Json
          artisan_profile_id?: string
          available_quantity?: number
          category_id?: string | null
          craft_origin?: string | null
          craft_story?: string | null
          created_at?: string
          currency?: string
          description?: string | null
          id?: string
          is_handmade?: boolean
          materials?: string[]
          min_order_quantity?: number
          price?: number
          published_at?: string | null
          short_description?: string | null
          slug?: string
          status?: string
          techniques?: string[]
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "products_artisan_profile_id_fkey"
            columns: ["artisan_profile_id"]
            isOneToOne: false
            referencedRelation: "artisan_profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "products_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "craft_categories"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          account_type: string
          created_at: string
          display_name: string
          id: string
          phone: string | null
          preferred_language: string
          updated_at: string
        }
        Insert: {
          account_type?: string
          created_at?: string
          display_name?: string
          id: string
          phone?: string | null
          preferred_language?: string
          updated_at?: string
        }
        Update: {
          account_type?: string
          created_at?: string
          display_name?: string
          id?: string
          phone?: string | null
          preferred_language?: string
          updated_at?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      artbook_accept_order: {
        Args: { p_artisan_user_id: string; p_order_id: string }
        Returns: Json
      }
      artbook_create_order: {
        Args: {
          p_buyer_user_id: string
          p_cart_id: string
          p_idempotency_key: string
          p_shipping_address: Json
        }
        Returns: Json
      }
      artbook_decide_approval: {
        Args: {
          p_approval_id: string
          p_decision: string
          p_owner_user_id: string
        }
        Returns: Json
      }
      artbook_request_listing_publication: {
        Args: { p_artisan_user_id: string; p_product_id: string }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
