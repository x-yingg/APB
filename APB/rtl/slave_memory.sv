module Memory(
    input logic        clk,
    input logic        rst_n,

    // Request from APB Slave
    input logic        req_i,
    input logic        rnw_i,
    input logic [3:0]  addr_i,
    input logic [31:0] wdata_i,

    // Response to APB Slave
    output logic       ready_o,
    output logic [31:0] rdata_o
);

	typedef enum logic [1:0] {
		IDLE,
		WAIT_STATE, 
		RESPOND     
	} state_t;
	
	state_t current_state, next_state;
	
	// Memory array & counters
	logic [31:0] mem [15:0];
	logic [1:0] wait_count;
	
	// --- NEW: LFSR Instantiation ---
	logic [3:0] lfsr_val; 
	
	LFSR4 random_gen (
		.clk    (clk),
		.rst_n  (rst_n),
		.lfsr_o (lfsr_val)
	);
	
	// --- SEQUENTIAL LOGIC (Memory & Counters) ---
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			current_state <= IDLE;
			wait_count    <= 0;
		end
		else begin
			current_state <= next_state;
			
			// Handle the wait counter
			if (current_state == IDLE && req_i == 1) begin
				// Grabs bottom 2 bits (0-3). If it's 00, force to 1.
				wait_count <= (lfsr_val[1:0] == 2'b00) ? 2'd1 : lfsr_val[1:0];
			end 
			else if (wait_count > 0) begin
				wait_count <= wait_count - 1; // Decrement safely
			end
			
			// Memory Write 
			if (current_state == WAIT_STATE && wait_count == 0 && req_rnw_i == 1'b0) begin
				mem[req_addr_i] <= req_wdata_i;
			end
		end
	end
		
	// --- COMBINATIONAL LOGIC (Outputs & Next State) ---
	always_comb begin
		// Default assignments to prevent latches
		next_state  = current_state;
		req_ready_o = 0;
		req_rdata_o = 0;
		
		case(current_state)
			IDLE: begin
				if (req_i == 1) begin
					next_state = WAIT_STATE;
				end
			end
			
			WAIT_STATE: begin
				if (wait_count == 0) begin
					next_state = RESPOND;
				end
			end
					
			RESPOND: begin
				req_ready_o = 1;
				
				// If it is a read transaction, drive the output data
				if (req_rnw_i == 1'b1) begin
					req_rdata_o = mem[req_addr_i]; 
				end
				
				next_state = IDLE;
			end
			
			default: next_state = IDLE;
		endcase
	end
	
endmodule