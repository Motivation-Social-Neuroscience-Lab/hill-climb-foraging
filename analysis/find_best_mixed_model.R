library(glmmTMB)

find_best_rr_model <- function(formula_fixed, rr_structure, data, rr_range = 1:10, family = binomial()) {
  aic_values <- numeric(length(rr_range))
  models <- vector("list", length(rr_range))
  
  for (i in seq_along(rr_range)) {
    k <- rr_range[i]
    cat("Fitting model with rr rank =", k, "\n")
    
    # Combine fixed and rr terms as a string
    full_formula_str <- paste0(
      formula_fixed,
      " + rr(", rr_structure, " | sid, ", k, ")"
    )
    
    # Convert to formula
    full_formula <- as.formula(full_formula_str)
    
    # Try fitting the model
    try({
      model_k <- glmmTMB(
        formula = full_formula,
        family = family,
        data = data,
        control = glmmTMBControl(optCtrl=list(iter.max=1e5,eval.max=1e5))
      )
      aic_values[i] <- AIC(model_k)
      models[[i]] <- model_k
    }, silent = TRUE)
  }
  
  # Find best model
  valid_indices <- which(!is.na(aic_values))
  if (length(valid_indices) == 0) {
    stop("All models failed to fit or returned NA AIC.")
  }
  
  best_i <- valid_indices[which.min(aic_values[valid_indices])]
  best_model <- models[[best_i]]
  
  cat("✅ Best rr(rank|sid, k):", rr_range[best_i], "\n")
  cat("📉 Lowest AIC:", aic_values[best_i], "\n")
  
  return(list(
    best_model = best_model,
    best_rank = rr_range[best_i],
    best_aic = aic_values[best_i],
    all_aics = aic_values,
    all_models = models
  ))
}
