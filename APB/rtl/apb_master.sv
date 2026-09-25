module APB_Master(
  input logic        clk,           
  input logic        rst_n,         
  input logic[1:0]   cmd_i,    

  input logic        pready_i,      
  input logic[31:0]  prdata_i,

  output logic       psel_o,       
  output logic       penable_o,    
  output logic[31:0] paddr_o,
  output logic       pwrite_o,     
  output logic[31:0] pwdata_o
);

	typedef enum logic [1:0] {
	    IDLE,
	    SETUP,
	    ACCESS
	} state_t;
	
	state_t current_state, next_state;
	logic[31:0] master_data;
	
	// --- SEQUENTIAL LOGIC (Memory) ---
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			current_state <= IDLE;
			master_data   <= 32'b0; 
			pwrite_o      <= 1'b0;      
			paddr_o       <= 32'b0;     
		end
		else begin
			current_state <= next_state;
			
			// 2. We now share the ACCESS state, so we must explicitly check 
			// if it's a READ (pwrite_o == 0) before capturing data.
			if (current_state == ACCESS && pready_i == 1 && pwrite_o == 1'b0) begin
				master_data <= prdata_i;
			end
			
			// Command capture 
			if (current_state == IDLE) begin
				if (cmd_i == 2'b01) begin
					pwrite_o <= 1'b0;           
					paddr_o  <= 32'hDEAD_CAFE;  
				end
				else if (cmd_i == 2'b10) begin
					pwrite_o <= 1'b1;           
					paddr_o  <= 32'hDEAD_CAFE;  
				end
			end
		end
	end
		
	// --- COMBINATIONAL LOGIC (Wires / Gates) ---
	always_comb begin
		// Default assignments
		next_state = current_state;
		psel_o     = 0;
		penable_o  = 0;
		pwdata_o   = 0; 
		
		case (current_state)
			IDLE: begin
				// Any non-zero command jumps to SETUP
				if (cmd_i == 2'b01 || cmd_i == 2'b10) begin
					next_state = SETUP;
				end
			end
			
			SETUP: begin
				psel_o = 1;
				// Only drive write data if the stored command was a Write
				if (pwrite_o == 1'b1) begin
					pwdata_o = master_data + 1;
				end
				next_state = ACCESS;
			end
			
			// 3. ACCESS state
			ACCESS: begin
				psel_o = 1;
				penable_o = 1;
				// Hold write data stable if the stored command was a Write
				if (pwrite_o == 1'b1) begin
					pwdata_o = master_data + 1;
				end
				
				if (pready_i == 1) begin
					next_state = IDLE;
				end
			end
		endcase
	end
	
endmodule
