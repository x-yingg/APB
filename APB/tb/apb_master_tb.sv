module tb;
	logic clk;
	logic rst_n;
	
	logic [1:0] cmd_i;
	logic pready_i;
	logic [31:0] prdata_i;

	logic psel_o;
	logic penable_o;
	logic [31:0] paddr_o;
	logic pwrite_o;
	logic [31:0] pwdata_o;
	
	// Instantiate the Device Under Test (DUT)
	APB_Master dut(.*);
	
	// Clock generation: 10ns period
	always #5 clk = ~clk;		
	
  	initial begin
		$monitor(
			"Time=%0t | clk=%b rst_n=%b cmd_i=%b | psel_o=%b penable_o=%b pwrite_o=%b paddr_o=%h pwdata_o=%h prdata_i=%h pready_i=%b",
			$time,
			clk,
			rst_n,
			cmd_i,
			psel_o,
			penable_o,
			pwrite_o,
			paddr_o,
			pwdata_o,
			prdata_i,
			pready_i);
	end
	
	initial begin
		$dumpfile("dump.vcd");
		$dumpvars(0, tb);
	end
  	
			
	// ---------------------------------------------------------
	// Test Stimulus
	// ---------------------------------------------------------
	initial begin
		// 1. Initialize inputs
		clk = 0;
		rst_n = 0;
		cmd_i = 2'b00;
		pready_i = 0;
		prdata_i = 32'h1234;
		
		// 2. Release reset
		#15; 
		rst_n = 1;
		
		// 3. READ TRANSACTION
		@(posedge clk);
		cmd_i = 2'b01;
		
		@(posedge clk);
		cmd_i = 2'b00; // Clear the command! The Master has already captured it.
		
		wait(penable_o == 1'b1);
		@(posedge clk);
		pready_i = 1;
		
		@(posedge clk);
		pready_i = 0;
		
		repeat(3) @(posedge clk);
		
		// 4. WRITE TRANSACTION
		@(posedge clk);
		cmd_i = 2'b10;
		
		@(posedge clk);
		cmd_i = 2'b00;
		
		wait(penable_o == 1'b1);
		@(posedge clk);
		pready_i = 1;
		
		@(posedge clk);
		pready_i = 0;
		
		// 5. End Simulation
		#20;
		$finish;
	end 	
endmodule	